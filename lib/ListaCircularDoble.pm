package ListaCircularDoble;

use strict;
use warnings;

sub new {
    my ($clase) = @_;
    return bless { cabeza => undef, tamanio => 0 }, $clase;
}

sub _nuevo_nodo {
    my ($nit, $nombre, $telefono, $direccion) = @_;
    return {
        nit       => $nit,
        nombre    => $nombre,
        telefono  => $telefono,
        direccion => $direccion,
        entregas  => [],
        ant       => undef,
        sig       => undef,
    };
}

sub insertar_o_actualizar {
    my ($self, $nit, $nombre, $telefono, $direccion, $factura, $fecha_entrega, $items) = @_;
    my $entrega = { factura => $factura, fecha_entrega => $fecha_entrega, items => $items };

    if (defined $self->{cabeza}) {
        my $actual = $self->{cabeza};
        do {
            if ($actual->{nit} eq $nit) {
                push @{$actual->{entregas}}, $entrega;
                return;
            }
            $actual = $actual->{sig};
        } while ($actual != $self->{cabeza});
    }

    my $nuevo = _nuevo_nodo($nit, $nombre, $telefono, $direccion);
    push @{$nuevo->{entregas}}, $entrega;

    unless (defined $self->{cabeza}) {
        $self->{cabeza} = $nuevo;
        $nuevo->{sig}   = $nuevo;
        $nuevo->{ant}   = $nuevo;
        $self->{tamanio}++;
        return;
    }

    my $ultimo          = $self->{cabeza}{ant};
    $ultimo->{sig}      = $nuevo;
    $nuevo->{ant}       = $ultimo;
    $nuevo->{sig}       = $self->{cabeza};
    $self->{cabeza}{ant}= $nuevo;
    $self->{tamanio}++;
}

sub buscar {
    my ($self, $nit) = @_;
    return undef unless defined $self->{cabeza};
    my $actual = $self->{cabeza};
    do {
        return $actual if $actual->{nit} eq $nit;
        $actual = $actual->{sig};
    } while ($actual != $self->{cabeza});
    return undef;
}

sub todos {
    my ($self) = @_;
    return () unless defined $self->{cabeza};
    my @lista;
    my $actual = $self->{cabeza};
    do { push @lista, $actual; $actual = $actual->{sig}; }
    while ($actual != $self->{cabeza});
    return @lista;
}

sub generar_dot {
    my ($self) = @_;
    my $dot = "digraph ListaProveedores {\n";
    $dot .= "    rankdir=LR;\n";
    $dot .= "    node [shape=rectangle, style=filled, fillcolor=\"#ffcc80\", fontname=\"Arial\"];\n";
    $dot .= "    edge [color=\"#e65100\"];\n";
    $dot .= "    label=\"Lista Circular Doble - Proveedores\";\n";
    $dot .= "    fontname=\"Arial Bold\";\n    fontsize=14;\n";
    my @nodos = $self->todos();
    for my $n (@nodos) {
        my $id  = "p_" . $n->{nit};
        $id =~ s/[-]/_/g;
        my $lbl = "NIT: $n->{nit}\\n$n->{nombre}\\nTel: $n->{telefono}";
        $dot .= "    \"$id\" [label=\"$lbl\"];\n";
    }
    for my $i (0 .. $#nodos) {
        my $id1 = "p_" . $nodos[$i]{nit};
        my $id2 = "p_" . $nodos[($i+1) % scalar(@nodos)]{nit};
        $id1 =~ s/[-]/_/g;
        $id2 =~ s/[-]/_/g;
        $dot .= "    \"$id1\" -> \"$id2\";\n";
        $dot .= "    \"$id2\" -> \"$id1\";\n";
    }
    $dot .= "}\n";
    return $dot;
}

1;