package ArbolB;

use strict;
use warnings;

my $ORDEN      = 4;
my $MAX_CLAVES = $ORDEN - 1;      # 3
my $MIN_CLAVES = int($ORDEN / 2) - 1; # 1

sub new {
    my ($clase) = @_;
    return bless { raiz => undef }, $clase;
}

sub _nuevo_nodo {
    return {
        claves  => [],
        hijos   => [],
        es_hoja => 1,
    };
}

sub _buscar_en_nodo {
    my ($nodo, $codigo) = @_;
    my @claves = @{$nodo->{claves}};
    for my $i (0 .. $#claves) {
        return $i if $claves[$i]{codigo} == $codigo;
    }
    return -1;
}

sub _indice_hijo {
    my ($nodo, $codigo) = @_;
    my @claves = @{$nodo->{claves}};
    my $i = 0;
    while ($i < scalar(@claves) && $codigo > $claves[$i]{codigo}) { $i++; }
    return $i;
}

sub _buscar_rec {
    my ($nodo, $codigo) = @_;
    return undef unless defined $nodo;
    my $idx = _buscar_en_nodo($nodo, $codigo);
    return $nodo->{claves}[$idx] if $idx >= 0;
    return undef if $nodo->{es_hoja};
    my $i = _indice_hijo($nodo, $codigo);
    return _buscar_rec($nodo->{hijos}[$i], $codigo);
}

sub buscar {
    my ($self, $codigo) = @_;
    return _buscar_rec($self->{raiz}, $codigo);
}

sub _dividir_hijo {
    my ($padre, $i, $hijo) = @_;
    my $nuevo = _nuevo_nodo();
    $nuevo->{es_hoja} = $hijo->{es_hoja};
    my $medio = int($MAX_CLAVES / 2);
    my @claves_hijo = @{$hijo->{claves}};
    $nuevo->{claves} = [ @claves_hijo[$medio+1 .. $#claves_hijo] ];
    my $clave_media  = $claves_hijo[$medio];
    $hijo->{claves}  = [ @claves_hijo[0 .. $medio-1] ];
    unless ($hijo->{es_hoja}) {
        my @hijos_hijo = @{$hijo->{hijos}};
        $nuevo->{hijos} = [ @hijos_hijo[$medio+1 .. $#hijos_hijo] ];
        $hijo->{hijos}  = [ @hijos_hijo[0 .. $medio] ];
    }
    splice(@{$padre->{claves}}, $i,   0, $clave_media);
    splice(@{$padre->{hijos}},  $i+1, 0, $nuevo);
}

sub _insertar_no_lleno {
    my ($nodo, $dato) = @_;
    if ($nodo->{es_hoja}) {
        my @claves = @{$nodo->{claves}};
        my $pos = 0;
        while ($pos < scalar(@claves) && $dato->{codigo} > $claves[$pos]{codigo}) { $pos++; }
        if ($pos < scalar(@claves) && $dato->{codigo} == $claves[$pos]{codigo}) {
            $nodo->{claves}[$pos] = $dato;
            return;
        }
        splice(@{$nodo->{claves}}, $pos, 0, $dato);
    } else {
        my $idx = _indice_hijo($nodo, $dato->{codigo});
        if ($idx > 0 && $nodo->{claves}[$idx-1]{codigo} == $dato->{codigo}) {
            $nodo->{claves}[$idx-1] = $dato;
            return;
        }
        if (scalar(@{$nodo->{hijos}[$idx]{claves}}) == $MAX_CLAVES) {
            _dividir_hijo($nodo, $idx, $nodo->{hijos}[$idx]);
            if    ($dato->{codigo} > $nodo->{claves}[$idx]{codigo}) { $idx++; }
            elsif ($dato->{codigo} == $nodo->{claves}[$idx]{codigo}) {
                $nodo->{claves}[$idx] = $dato;
                return;
            }
        }
        _insertar_no_lleno($nodo->{hijos}[$idx], $dato);
    }
}

sub insertar {
    my ($self, $codigo, $nombre, $fabricante, $precio, $cantidad, $fecha_vencimiento, $nivel_minimo) = @_;
    my $dato = {
        codigo            => $codigo,
        nombre            => $nombre,
        fabricante        => $fabricante,
        precio            => $precio,
        cantidad          => $cantidad,
        fecha_vencimiento => $fecha_vencimiento // '',
        nivel_minimo      => $nivel_minimo,
    };
    unless (defined $self->{raiz}) {
        $self->{raiz} = _nuevo_nodo();
        push @{$self->{raiz}{claves}}, $dato;
        return;
    }
    if (scalar(@{$self->{raiz}{claves}}) == $MAX_CLAVES) {
        my $nueva_raiz = _nuevo_nodo();
        $nueva_raiz->{es_hoja} = 0;
        push @{$nueva_raiz->{hijos}}, $self->{raiz};
        _dividir_hijo($nueva_raiz, 0, $self->{raiz});
        $self->{raiz} = $nueva_raiz;
    }
    _insertar_no_lleno($self->{raiz}, $dato);
}

sub _predecesor {
    my ($nodo) = @_;
    while (!$nodo->{es_hoja}) { $nodo = $nodo->{hijos}[-1]; }
    return $nodo->{claves}[-1];
}

sub _sucesor {
    my ($nodo) = @_;
    while (!$nodo->{es_hoja}) { $nodo = $nodo->{hijos}[0]; }
    return $nodo->{claves}[0];
}

sub _fusionar {
    my ($padre, $i) = @_;
    my $izq = $padre->{hijos}[$i];
    my $der  = $padre->{hijos}[$i+1];
    push @{$izq->{claves}}, $padre->{claves}[$i];
    push @{$izq->{claves}}, @{$der->{claves}};
    push @{$izq->{hijos}}, @{$der->{hijos}} unless $izq->{es_hoja};
    splice(@{$padre->{claves}}, $i,   1);
    splice(@{$padre->{hijos}},  $i+1, 1);
}

sub _eliminar_rec {
    my ($nodo, $codigo) = @_;
    return unless defined $nodo;

    my $idx = -1;
    for my $i (0 .. $#{$nodo->{claves}}) {
        if ($nodo->{claves}[$i]{codigo} == $codigo) { $idx = $i; last; }
    }

    if ($idx >= 0) {
        if ($nodo->{es_hoja}) {
            splice(@{$nodo->{claves}}, $idx, 1);
        } else {
            my $hijo_izq = $nodo->{hijos}[$idx];
            my $hijo_der = $nodo->{hijos}[$idx+1];
            if (scalar(@{$hijo_izq->{claves}}) >= $ORDEN/2) {
                my $pred = _predecesor($hijo_izq);
                $nodo->{claves}[$idx] = $pred;
                _eliminar_rec($hijo_izq, $pred->{codigo});
            } elsif (scalar(@{$hijo_der->{claves}}) >= $ORDEN/2) {
                my $suc = _sucesor($hijo_der);
                $nodo->{claves}[$idx] = $suc;
                _eliminar_rec($hijo_der, $suc->{codigo});
            } else {
                _fusionar($nodo, $idx);
                _eliminar_rec($nodo->{hijos}[$idx], $codigo);
            }
        }
    } else {
        return if $nodo->{es_hoja};
        my $i    = _indice_hijo($nodo, $codigo);
        my $hijo = $nodo->{hijos}[$i];
        if (scalar(@{$hijo->{claves}}) < $ORDEN/2) {
            if ($i > 0 && scalar(@{$nodo->{hijos}[$i-1]{claves}}) >= $ORDEN/2) {
                my $herm = $nodo->{hijos}[$i-1];
                unshift @{$hijo->{claves}}, $nodo->{claves}[$i-1];
                $nodo->{claves}[$i-1] = pop @{$herm->{claves}};
                unshift @{$hijo->{hijos}}, pop @{$herm->{hijos}} unless $hijo->{es_hoja};
            } elsif ($i < scalar(@{$nodo->{hijos}})-1 && scalar(@{$nodo->{hijos}[$i+1]{claves}}) >= $ORDEN/2) {
                my $herm = $nodo->{hijos}[$i+1];
                push @{$hijo->{claves}}, $nodo->{claves}[$i];
                $nodo->{claves}[$i] = shift @{$herm->{claves}};
                push @{$hijo->{hijos}}, shift @{$herm->{hijos}} unless $hijo->{es_hoja};
            } else {
                if ($i < scalar(@{$nodo->{hijos}})-1) {
                    _fusionar($nodo, $i);
                } else {
                    _fusionar($nodo, $i-1);
                    $i--;
                }
                $hijo = $nodo->{hijos}[$i];
            }
        }
        _eliminar_rec($hijo, $codigo);
    }
}

sub eliminar {
    my ($self, $codigo) = @_;
    return unless defined $self->{raiz};
    _eliminar_rec($self->{raiz}, $codigo);
    if (scalar(@{$self->{raiz}{claves}}) == 0 && !$self->{raiz}{es_hoja}) {
        $self->{raiz} = $self->{raiz}{hijos}[0];
    }
}

sub _inorden_rec {
    my ($nodo, $lista) = @_;
    return unless defined $nodo;
    my $n = scalar(@{$nodo->{claves}});
    for my $i (0 .. $n-1) {
        _inorden_rec($nodo->{hijos}[$i], $lista) unless $nodo->{es_hoja};
        push @$lista, $nodo->{claves}[$i];
    }
    _inorden_rec($nodo->{hijos}[$n], $lista) unless $nodo->{es_hoja};
}

sub inorden {
    my ($self) = @_;
    my @lista;
    _inorden_rec($self->{raiz}, \@lista);
    return @lista;
}

sub generar_dot {
    my ($self) = @_;
    my $dot = "digraph ArbolB {\n";
    $dot .= "    node [fontname=\"Arial\"];\n";
    $dot .= "    edge [color=\"#f57c00\"];\n";
    $dot .= "    label=\"Arbol B Orden 4 - Inventario de Suministros\";\n";
    $dot .= "    fontname=\"Arial Bold\";\n    fontsize=16;\n    rankdir=TB;\n";
    my $cont = 0;
    $self->_dot_nodo($self->{raiz}, \$dot, \$cont, undef);
    $dot .= "}\n";
    return $dot;
}

sub _dot_nodo {
    my ($self, $nodo, $dot_ref, $cnt_ref, $padre_id) = @_;
    return unless defined $nodo;
    my $id = "b" . $$cnt_ref;
    $$cnt_ref++;
    my $n     = scalar(@{$nodo->{claves}});
    my $color = ($n == $MAX_CLAVES) ? '"#fff176"' : '"#a5d6a7"';
    my $lbl   = "{";
    for my $i (0 .. $n-1) {
        $lbl .= $nodo->{claves}[$i]{codigo} . "\\n" . $nodo->{claves}[$i]{nombre};
        $lbl .= "|" if $i < $n-1;
    }
    $lbl .= "} ($n/$MAX_CLAVES)";
    $$dot_ref .= "    \"$id\" [shape=record, label=\"$lbl\", style=filled, fillcolor=$color];\n";
    unless ($nodo->{es_hoja}) {
        for my $i (0 .. $#{$nodo->{hijos}}) {
            my $hijo_id = "b" . $$cnt_ref;
            $self->_dot_nodo($nodo->{hijos}[$i], $dot_ref, $cnt_ref, $id);
            $$dot_ref .= "    \"$id\" -> \"$hijo_id\";\n";
        }
    }
}

1;