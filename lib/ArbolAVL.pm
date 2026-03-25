package ArbolAVL;

use strict;
use warnings;

sub new {
    my ($clase) = @_;
    return bless { raiz => undef }, $clase;
}

sub _nuevo_nodo {
    my ($numero_colegio, $nombre, $tipo, $departamento, $especialidad, $contrasena) = @_;
    return {
        numero_colegio => $numero_colegio,
        nombre         => $nombre,
        tipo           => $tipo,
        departamento   => $departamento,
        especialidad   => $especialidad // '',
        contrasena     => $contrasena,
        izq            => undef,
        der            => undef,
        altura         => 1,
    };
}

sub _altura {
    my ($nodo) = @_;
    return 0 unless defined $nodo;
    return $nodo->{altura};
}

sub _actualizar_altura {
    my ($nodo) = @_;
    my $hi = _altura($nodo->{izq});
    my $hd = _altura($nodo->{der});
    $nodo->{altura} = 1 + ($hi > $hd ? $hi : $hd);
}

sub _balance {
    my ($nodo) = @_;
    return 0 unless defined $nodo;
    return _altura($nodo->{izq}) - _altura($nodo->{der});
}

sub _rotar_derecha {
    my ($y) = @_;
    my $x  = $y->{izq};
    my $t2 = $x->{der};
    $x->{der} = $y;
    $y->{izq} = $t2;
    _actualizar_altura($y);
    _actualizar_altura($x);
    return $x;
}

sub _rotar_izquierda {
    my ($x) = @_;
    my $y  = $x->{der};
    my $t2 = $y->{izq};
    $y->{izq} = $x;
    $x->{der} = $t2;
    _actualizar_altura($x);
    _actualizar_altura($y);
    return $y;
}

sub _insertar_rec {
    my ($nodo, $numero_colegio, $nombre, $tipo, $departamento, $especialidad, $contrasena) = @_;

    unless (defined $nodo) {
        return _nuevo_nodo($numero_colegio, $nombre, $tipo, $departamento, $especialidad, $contrasena);
    }

    if ($numero_colegio lt $nodo->{numero_colegio}) {
        $nodo->{izq} = _insertar_rec($nodo->{izq}, $numero_colegio, $nombre, $tipo, $departamento, $especialidad, $contrasena);
    } elsif ($numero_colegio gt $nodo->{numero_colegio}) {
        $nodo->{der} = _insertar_rec($nodo->{der}, $numero_colegio, $nombre, $tipo, $departamento, $especialidad, $contrasena);
    } else {
        return $nodo;
    }

    _actualizar_altura($nodo);
    my $bal = _balance($nodo);
    if ($bal > 1 && $numero_colegio lt $nodo->{izq}{numero_colegio}) {
        return _rotar_derecha($nodo);
    }
    if ($bal < -1 && $numero_colegio gt $nodo->{der}{numero_colegio}) {
        return _rotar_izquierda($nodo);
    }
    if ($bal > 1 && $numero_colegio gt $nodo->{izq}{numero_colegio}) {
        $nodo->{izq} = _rotar_izquierda($nodo->{izq});
        return _rotar_derecha($nodo);
    }
    if ($bal < -1 && $numero_colegio lt $nodo->{der}{numero_colegio}) {
        $nodo->{der} = _rotar_derecha($nodo->{der});
        return _rotar_izquierda($nodo);
    }

    return $nodo;
}

sub insertar {
    my ($self, $numero_colegio, $nombre, $tipo, $departamento, $especialidad, $contrasena) = @_;
    $self->{raiz} = _insertar_rec(
        $self->{raiz}, $numero_colegio, $nombre, $tipo, $departamento, $especialidad, $contrasena
    );
}

sub buscar {
    my ($self, $numero_colegio) = @_;
    my $nodo = $self->{raiz};
    while (defined $nodo) {
        if    ($numero_colegio eq $nodo->{numero_colegio}) { return $nodo; }
        elsif ($numero_colegio lt $nodo->{numero_colegio}) { $nodo = $nodo->{izq}; }
        else                                               { $nodo = $nodo->{der}; }
    }
    return undef;
}

sub _minimo {
    my ($nodo) = @_;
    while (defined $nodo->{izq}) { $nodo = $nodo->{izq}; }
    return $nodo;
}

sub _eliminar_rec {
    my ($nodo, $numero_colegio) = @_;
    return undef unless defined $nodo;

    if ($numero_colegio lt $nodo->{numero_colegio}) {
        $nodo->{izq} = _eliminar_rec($nodo->{izq}, $numero_colegio);
    } elsif ($numero_colegio gt $nodo->{numero_colegio}) {
        $nodo->{der} = _eliminar_rec($nodo->{der}, $numero_colegio);
    } else {
        if (!defined $nodo->{izq} || !defined $nodo->{der}) {
            $nodo = defined($nodo->{izq}) ? $nodo->{izq} : $nodo->{der};
        } else {
            my $sucesor = _minimo($nodo->{der});
            $nodo->{numero_colegio} = $sucesor->{numero_colegio};
            $nodo->{nombre}         = $sucesor->{nombre};
            $nodo->{tipo}           = $sucesor->{tipo};
            $nodo->{departamento}   = $sucesor->{departamento};
            $nodo->{especialidad}   = $sucesor->{especialidad};
            $nodo->{contrasena}     = $sucesor->{contrasena};
            $nodo->{der} = _eliminar_rec($nodo->{der}, $sucesor->{numero_colegio});
        }
    }

    return undef unless defined $nodo;

    _actualizar_altura($nodo);
    my $bal = _balance($nodo);

    if ($bal > 1  && _balance($nodo->{izq}) >= 0)  { return _rotar_derecha($nodo); }
    if ($bal > 1  && _balance($nodo->{izq}) < 0)   { $nodo->{izq} = _rotar_izquierda($nodo->{izq}); return _rotar_derecha($nodo); }
    if ($bal < -1 && _balance($nodo->{der}) <= 0)  { return _rotar_izquierda($nodo); }
    if ($bal < -1 && _balance($nodo->{der}) > 0)   { $nodo->{der} = _rotar_derecha($nodo->{der}); return _rotar_izquierda($nodo); }

    return $nodo;
}

sub eliminar {
    my ($self, $numero_colegio) = @_;
    $self->{raiz} = _eliminar_rec($self->{raiz}, $numero_colegio);
}

sub _inorden_rec {
    my ($nodo, $lista) = @_;
    return unless defined $nodo;
    _inorden_rec($nodo->{izq}, $lista);
    push @$lista, $nodo;
    _inorden_rec($nodo->{der}, $lista);
}

sub _preorden_rec {
    my ($nodo, $lista) = @_;
    return unless defined $nodo;
    push @$lista, $nodo;
    _preorden_rec($nodo->{izq}, $lista);
    _preorden_rec($nodo->{der}, $lista);
}

sub _postorden_rec {
    my ($nodo, $lista) = @_;
    return unless defined $nodo;
    _postorden_rec($nodo->{izq}, $lista);
    _postorden_rec($nodo->{der}, $lista);
    push @$lista, $nodo;
}

sub inorden   { my ($self) = @_; my @l; _inorden_rec($self->{raiz},   \@l); return @l; }
sub preorden  { my ($self) = @_; my @l; _preorden_rec($self->{raiz},  \@l); return @l; }
sub postorden { my ($self) = @_; my @l; _postorden_rec($self->{raiz}, \@l); return @l; }

sub generar_dot {
    my ($self) = @_;
    my $dot = "digraph AVL {\n";
    $dot .= "    node [shape=circle, style=filled, fillcolor=\"#4fc3f7\", fontname=\"Arial\"];\n";
    $dot .= "    edge [color=\"#555555\"];\n";
    $dot .= "    label=\"Arbol AVL - Personal Medico\";\n";
    $dot .= "    fontname=\"Arial Bold\";\n    fontsize=16;\n";

    my @cola = ($self->{raiz});
    while (@cola) {
        my $n = shift @cola;
        next unless defined $n;
        my $id  = $n->{numero_colegio};
        my $lbl = "$id\\n$n->{nombre}\\n$n->{tipo} | $n->{departamento}";
        $dot .= "    \"$id\" [label=\"$lbl\"];\n";
        if (defined $n->{izq}) {
            $dot .= "    \"$id\" -> \"$n->{izq}{numero_colegio}\" [label=\"I\"];\n";
            push @cola, $n->{izq};
        }
        if (defined $n->{der}) {
            $dot .= "    \"$id\" -> \"$n->{der}{numero_colegio}\" [label=\"D\"];\n";
            push @cola, $n->{der};
        }
    }
    $dot .= "}\n";
    return $dot;
}

1;