package Reportes;

use strict;
use warnings;
use File::Path qw(make_path);

my $DIR_REPORTES = "reportes";

sub _asegurar_directorio {
    make_path($DIR_REPORTES) unless -d $DIR_REPORTES;
}

sub _generar_png {
    my ($nombre, $codigo_dot) = @_;
    _asegurar_directorio();
    my $dot_file = "$DIR_REPORTES/$nombre.dot";
    my $png_file = "$DIR_REPORTES/$nombre.png";
    open(my $fh, '>:utf8', $dot_file) or return undef;
    print $fh $codigo_dot;
    close($fh);
    my $salida = `dot -Tpng "$dot_file" -o "$png_file" 2>&1`;
    if ($? != 0) {
        warn "Error generando reporte '$nombre': $salida";
        return undef;
    }
    return $png_file;
}

sub reporte_avl         { my ($avl)       = @_; return _generar_png("reporte_avl",         $avl->generar_dot());       }
sub reporte_bst         { my ($bst)       = @_; return _generar_png("reporte_bst",         $bst->generar_dot());       }
sub reporte_arbol_b     { my ($arbol_b)   = @_; return _generar_png("reporte_arbol_b",     $arbol_b->generar_dot());   }
sub reporte_matriz      { my ($matriz)    = @_; return _generar_png("reporte_matriz",      $matriz->generar_dot());    }
sub reporte_medicamentos{ my ($lista_med) = @_; return _generar_png("reporte_medicamentos",$lista_med->generar_dot()); }
sub reporte_proveedores { my ($lista_prov)= @_; return _generar_png("reporte_proveedores", $lista_prov->generar_dot());}

1;