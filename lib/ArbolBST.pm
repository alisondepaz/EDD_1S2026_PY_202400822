package ArbolBST;

use strict;
use warnings;

sub new {
    my ($clase) = @_;
    return bless { raiz => undef }, $clase;
}

sub _nuevo_nodo {
    my ($codigo, $nombre, $fabricante, $precio, $cantidad, $fecha_ingreso, $nivel_minimo) = @_;
    return {
        codigo        => $codigo,
        nombre        => $nombre,
        fabricante    => $fabricante,
        precio        => $precio,
        cantidad      => $cantidad,
        fecha_ingreso => $fecha_ingreso // '',
        nivel_minimo  => $nivel_minimo,
        izq           => undef,
        der           => undef,
    };
}

sub _insertar_rec {
    my ($nodo, $codigo, $nombre, $fabricante, $precio, $cantidad, $fecha_ingreso, $nivel_minimo) = @_;

    unless (defined $nodo) {
        return _nuevo_nodo($codigo, $nombre, $fabricante, $precio, $cantidad, $fecha_ingreso, $nivel_minimo);
    }

    if ($codigo < $nodo->{codigo}) {
        $nodo->{izq} = _insertar_rec($nodo->{izq}, $codigo, $nombre, $fabricante, $precio, $cantidad, $fecha_ingreso, $nivel_minimo);
    } elsif ($codigo > $nodo->{codigo}) {
        $nodo->{der} = _insertar_rec($nodo->{der}, $codigo, $nombre, $fabricante, $precio, $cantidad, $fecha_ingreso, $nivel_minimo);
    } else {
        $nodo->{nombre}        = $nombre;
        $nodo->{fabricante}    = $fabricante;
        $nodo->{precio}        = $precio;
        $nodo->{cantidad}      = $cantidad;
        $nodo->{fecha_ingreso} = $fecha_ingreso // '';
        $nodo->{nivel_minimo}  = $nivel_minimo;
    }
    return $nodo;
}

sub insertar {
    my ($self, $codigo, $nombre, $fabricante, $precio, $cantidad, $fecha_ingreso, $nivel_minimo) = @_;
    $self->{raiz} = _insertar_rec(
        $self->{raiz}, $codigo, $nombre, $fabricante, $precio, $cantidad, $fecha_ingreso, $nivel_minimo
    );
}

sub buscar {
    my ($self, $codigo) = @_;
    my $nodo = $self->{raiz};
    while (defined $nodo) {
        if    ($codigo == $nodo->{codigo}) { return $nodo; }
        elsif ($codigo <  $nodo->{codigo}) { $nodo = $nodo->{izq}; }
        else                               { $nodo = $nodo->{der}; }
    }
    return undef;
}

sub _minimo {
    my ($nodo) = @_;
    while (defined $nodo->{izq}) { $nodo = $nodo->{izq}; }
    return $nodo;
}

sub _eliminar_rec {
    my ($nodo, $codigo) = @_;
    return undef unless defined $nodo;

    if ($codigo < $nodo->{codigo}) {
        $nodo->{izq} = _eliminar_rec($nodo->{izq}, $codigo);
    } elsif ($codigo > $nodo->{codigo}) {
        $nodo->{der} = _eliminar_rec($nodo->{der}, $codigo);
    } else {
        if (!defined $nodo->{izq}) { return $nodo->{der}; }
        if (!defined $nodo->{der}) { return $nodo->{izq}; }
        my $sucesor = _minimo($nodo->{der});
        $nodo->{codigo}        = $sucesor->{codigo};
        $nodo->{nombre}        = $sucesor->{nombre};
        $nodo->{fabricante}    = $sucesor->{fabricante};
        $nodo->{precio}        = $sucesor->{precio};
        $nodo->{cantidad}      = $sucesor->{cantidad};
        $nodo->{fecha_ingreso} = $sucesor->{fecha_ingreso};
        $nodo->{nivel_minimo}  = $sucesor->{nivel_minimo};
        $nodo->{der} = _eliminar_rec($nodo->{der}, $sucesor->{codigo});
    }
    return $nodo;
}

sub eliminar {
    my ($self, $codigo) = @_;
    $self->{raiz} = _eliminar_rec($self->{raiz}, $codigo);
}

sub _inorden_rec {
    my ($n, $l) = @_;
    return unless defined $n;
    _inorden_rec($n->{izq}, $l);
    push @$l, $n;
    _inorden_rec($n->{der}, $l);
}

sub _preorden_rec {
    my ($n, $l) = @_;
    return unless defined $n;
    push @$l, $n;
    _preorden_rec($n->{izq}, $l);
    _preorden_rec($n->{der}, $l);
}

sub _postorden_rec {
    my ($n, $l) = @_;
    return unless defined $n;
    _postorden_rec($n->{izq}, $l);
    _postorden_rec($n->{der}, $l);
    push @$l, $n;
}

sub inorden   { my ($self) = @_; my @l; _inorden_rec($self->{raiz},   \@l); return @l; }
sub preorden  { my ($self) = @_; my @l; _preorden_rec($self->{raiz},  \@l); return @l; }
sub postorden { my ($self) = @_; my @l; _postorden_rec($self->{raiz}, \@l); return @l; }

sub generar_dot {
    my ($self) = @_;
    my $dot = "digraph BST {\n";
    $dot .= "    node [shape=rectangle, style=filled, fillcolor=\"#a5d6a7\", fontname=\"Arial\"];\n";
    $dot .= "    edge [color=\"#388e3c\"];\n";
    $dot .= "    label=\"Arbol BST - Inventario de Equipos Medicos\";\n";
    $dot .= "    fontname=\"Arial Bold\";\n    fontsize=16;\n";

    my @pila = ($self->{raiz});
    while (@pila) {
        my $n = shift @pila;
        next unless defined $n;
        my $id  = sprintf("n%s", $n->{codigo});
        my $lbl = "Codigo: $n->{codigo}\\n$n->{nombre}\\nCantidad: $n->{cantidad}\\nFabricante: $n->{fabricante}";
        $dot .= "    \"$id\" [label=\"$lbl\"];\n";
        if (defined $n->{izq}) {
            my $izq_id = sprintf("n%s", $n->{izq}{codigo});
            $dot .= "    \"$id\" -> \"$izq_id\" [label=\"I\"];\n";
            push @pila, $n->{izq};
        }
        if (defined $n->{der}) {
            my $der_id = sprintf("n%s", $n->{der}{codigo});
            $dot .= "    \"$id\" -> \"$der_id\" [label=\"D\"];\n";
            push @pila, $n->{der};
        }
    }
    $dot .= "}\n";
    return $dot;
}

1;