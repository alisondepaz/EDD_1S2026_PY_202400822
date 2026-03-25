package MatrizDispersa;

use strict;
use warnings;

sub new {
    my ($clase) = @_;
    return bless {
        filas    => {},
        columnas => {},
        celdas   => {},
    }, $clase;
}

sub agregar {
    my ($self, $nit_proveedor, $nombre_proveedor, $fabricante, $cantidad) = @_;
    $self->{filas}{$nit_proveedor} = $nombre_proveedor;
    $self->{columnas}{$fabricante} = $fabricante;
    my $llave = "$nit_proveedor|$fabricante";
    $self->{celdas}{$llave} = ($self->{celdas}{$llave} // 0) + $cantidad;
}

sub consultar {
    my ($self, $nit_proveedor, $fabricante) = @_;
    my $llave = "$nit_proveedor|$fabricante";
    return $self->{celdas}{$llave} // 0;
}

sub proveedores      { return sort keys %{$_[0]->{filas}};    }
sub fabricantes      { return sort keys %{$_[0]->{columnas}}; }
sub nombre_proveedor { my ($self, $nit) = @_; return $self->{filas}{$nit} // $nit; }

sub celdas_no_vacias {
    my ($self) = @_;
    my @resultado;
    for my $llave (keys %{$self->{celdas}}) {
        my ($nit, $fab) = split /\|/, $llave;
        push @resultado, {
            nit        => $nit,
            proveedor  => $self->{filas}{$nit} // $nit,
            fabricante => $fab,
            cantidad   => $self->{celdas}{$llave},
        };
    }
    return sort { $a->{proveedor} cmp $b->{proveedor} } @resultado;
}

sub generar_dot {
    my ($self) = @_;
    my $dot = "digraph MatrizDispersa {\n";
    $dot .= "    rankdir=TB;\n";
    $dot .= "    node [fontname=\"Arial\"];\n";
    $dot .= "    label=\"Matriz Dispersa - Proveedor vs Fabricante\";\n";
    $dot .= "    fontname=\"Arial Bold\";\n    fontsize=14;\n\n";

    $dot .= "    subgraph cluster_proveedores {\n        label=\"Proveedores\"; style=dashed;\n";
    for my $nit ($self->proveedores()) {
        my $id     = "prov_$nit"; $id =~ s/[-]/_/g;
        my $nombre = $self->{filas}{$nit};
        $dot .= "        \"$id\" [shape=rectangle, style=filled, fillcolor=\"#90caf9\", label=\"$nombre\\n($nit)\"];\n";
    }
    $dot .= "    }\n\n";

    $dot .= "    subgraph cluster_fabricantes {\n        label=\"Fabricantes\"; style=dashed;\n";
    for my $fab ($self->fabricantes()) {
        my $id = "fab_$fab"; $id =~ s/[^a-zA-Z0-9_]/_/g;
        $dot .= "        \"$id\" [shape=rectangle, style=filled, fillcolor=\"#a5d6a7\", label=\"$fab\"];\n";
    }
    $dot .= "    }\n\n";

    for my $celda ($self->celdas_no_vacias()) {
        my $nit  = $celda->{nit};
        my $fab  = $celda->{fabricante};
        my $cant = $celda->{cantidad};
        my $prov_id = "prov_$nit"; $prov_id =~ s/[-]/_/g;
        my $fab_id  = "fab_$fab";  $fab_id  =~ s/[^a-zA-Z0-9_]/_/g;
        my $val_id  = "val_${nit}_${fab}"; $val_id =~ s/[^a-zA-Z0-9_]/_/g;
        $dot .= "    \"$val_id\" [shape=circle, style=filled, fillcolor=\"#ffcc80\", label=\"$cant\"];\n";
        $dot .= "    \"$prov_id\" -> \"$val_id\" [color=\"#1565c0\"];\n";
        $dot .= "    \"$fab_id\"  -> \"$val_id\" [color=\"#2e7d32\"];\n";
    }

    $dot .= "}\n";
    return $dot;
}

1;