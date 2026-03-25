package ListaDoble;

use strict;
use warnings;

sub new {
    my ($clase) = @_;
    return bless { cabeza => undef, cola => undef, tamanio => 0 }, $clase;
}

sub _nuevo_nodo {
    my ($codigo, $nombre, $principio_activo, $fabricante, $precio, $cantidad, $fecha_vencimiento, $nivel_minimo) = @_;
    return {
        codigo            => $codigo,
        nombre            => $nombre,
        principio_activo  => $principio_activo // '',
        fabricante        => $fabricante,
        precio            => $precio,
        cantidad          => $cantidad,
        fecha_vencimiento => $fecha_vencimiento // '',
        nivel_minimo      => $nivel_minimo,
        ant               => undef,
        sig               => undef,
    };
}

sub insertar {
    my ($self, $codigo, $nombre, $principio_activo, $fabricante, $precio, $cantidad, $fecha_vencimiento, $nivel_minimo) = @_;
    my $nuevo = _nuevo_nodo($codigo, $nombre, $principio_activo, $fabricante, $precio, $cantidad, $fecha_vencimiento, $nivel_minimo);

    unless (defined $self->{cabeza}) {
        $self->{cabeza} = $nuevo;
        $self->{cola}   = $nuevo;
        $self->{tamanio}++;
        return;
    }

    my $actual = $self->{cabeza};
    while (defined $actual) {
        if ($codigo == $actual->{codigo}) {
            $actual->{nombre}            = $nombre;
            $actual->{principio_activo}  = $principio_activo // '';
            $actual->{fabricante}        = $fabricante;
            $actual->{precio}            = $precio;
            $actual->{cantidad}          = $cantidad;
            $actual->{fecha_vencimiento} = $fecha_vencimiento // '';
            $actual->{nivel_minimo}      = $nivel_minimo;
            return;
        } elsif ($codigo < $actual->{codigo}) {
            $nuevo->{sig} = $actual;
            $nuevo->{ant} = $actual->{ant};
            if (defined $actual->{ant}) { $actual->{ant}{sig} = $nuevo; }
            else                        { $self->{cabeza}     = $nuevo; }
            $actual->{ant} = $nuevo;
            $self->{tamanio}++;
            return;
        }
        $actual = $actual->{sig};
    }

    $nuevo->{ant}      = $self->{cola};
    $self->{cola}{sig} = $nuevo;
    $self->{cola}      = $nuevo;
    $self->{tamanio}++;
}

sub buscar {
    my ($self, $codigo) = @_;
    my $actual = $self->{cabeza};
    while (defined $actual) {
        return $actual if $actual->{codigo} == $codigo;
        $actual = $actual->{sig};
    }
    return undef;
}

sub eliminar {
    my ($self, $codigo) = @_;
    my $actual = $self->{cabeza};
    while (defined $actual) {
        if ($actual->{codigo} == $codigo) {
            if (defined $actual->{ant}) { $actual->{ant}{sig} = $actual->{sig}; }
            else                        { $self->{cabeza}     = $actual->{sig}; }
            if (defined $actual->{sig}) { $actual->{sig}{ant} = $actual->{ant}; }
            else                        { $self->{cola}       = $actual->{ant}; }
            $self->{tamanio}--;
            return 1;
        }
        $actual = $actual->{sig};
    }
    return 0;
}

sub todos {
    my ($self) = @_;
    my @lista;
    my $actual = $self->{cabeza};
    while (defined $actual) { push @lista, $actual; $actual = $actual->{sig}; }
    return @lista;
}

sub generar_dot {
    my ($self) = @_;
    my $dot = "digraph ListaMedicamentos {\n";
    $dot .= "    rankdir=LR;\n";
    $dot .= "    node [shape=rectangle, style=filled, fillcolor=\"#ce93d8\", fontname=\"Arial\"];\n";
    $dot .= "    edge [color=\"#7b1fa2\"];\n";
    $dot .= "    label=\"Lista Doblemente Enlazada - Medicamentos\";\n";
    $dot .= "    fontname=\"Arial Bold\";\n    fontsize=14;\n";
    my @nodos;
    my $actual = $self->{cabeza};
    while (defined $actual) { push @nodos, $actual; $actual = $actual->{sig}; }
    for my $nodo (@nodos) {
        my $id  = "m" . $nodo->{codigo};
        my $lbl = "Cod: $nodo->{codigo}\\n$nodo->{nombre}\\nCant: $nodo->{cantidad}\\nVence: $nodo->{fecha_vencimiento}";
        $dot .= "    \"$id\" [label=\"$lbl\"];\n";
    }
    for my $i (0 .. $#nodos-1) {
        my $id1 = "m" . $nodos[$i]{codigo};
        my $id2 = "m" . $nodos[$i+1]{codigo};
        $dot .= "    \"$id1\" -> \"$id2\";\n";
        $dot .= "    \"$id2\" -> \"$id1\";\n";
    }
    $dot .= "}\n";
    return $dot;
}

1;