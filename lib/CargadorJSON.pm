package CargadorJSON;

use strict;
use warnings;
use JSON;

sub cargar_inventario {
    my ($ruta_archivo, $avl, $bst, $arbol_b, $lista_med, $lista_prov, $matriz) = @_;
    my %resultado = (exitosos => 0, errores => 0, advertencias => [], mensajes => []);

    open(my $fh, '<:utf8', $ruta_archivo) or do {
        push @{$resultado{advertencias}}, "No se pudo abrir el archivo: $!";
        return \%resultado;
    };
    my $contenido = do { local $/; <$fh> };
    close($fh);

    my $datos;
    eval { $datos = decode_json($contenido); };
    if ($@) {
        push @{$resultado{advertencias}}, "Error al parsear JSON: $@";
        return \%resultado;
    }

    unless (ref($datos) eq 'HASH' && exists $datos->{proveedor}) {
        push @{$resultado{advertencias}}, "El JSON no tiene la clave 'proveedor'.";
        return \%resultado;
    }

    for my $prov (@{$datos->{proveedor}}) {
        unless ($prov->{nit} && $prov->{nombre}) {
            push @{$resultado{advertencias}}, "Proveedor sin NIT o nombre, se omite.";
            next;
        }
        my $nit     = $prov->{nit};
        my $nombre  = $prov->{nombre};
        my $tel     = $prov->{telefono}       // 'N/A';
        my $dir     = $prov->{direccion}      // 'N/A';
        my $factura = $prov->{numero_factura} // 'SIN-FACTURA';
        my $fecha   = $prov->{fecha_entrega}  // 'SIN-FECHA';

        $lista_prov->insertar_o_actualizar($nit, $nombre, $tel, $dir, $factura, $fecha, []);

        for my $item (@{$prov->{entrega} // []}) {
            my $tipo     = $item->{tipo}            // '';
            my $codigo   = $item->{codigo}          // '';
            my $itnombre = $item->{nombre}          // '';
            my $fab      = $item->{fabricante}      // '';
            my $precio   = $item->{precio_unitario} // 0;
            my $cant     = $item->{cantidad}        // 0;
            my $nivel    = $item->{nivel_minimo}    // 0;

            unless ($tipo && $codigo && $itnombre) {
                push @{$resultado{advertencias}}, "Item sin tipo/codigo/nombre en entrega de $nombre, se omite.";
                $resultado{errores}++;
                next;
            }
            unless ($cant > 0) {
                push @{$resultado{advertencias}}, "Item codigo $codigo tiene cantidad <= 0, se omite.";
                $resultado{errores}++;
                next;
            }

            if ($tipo eq 'MEDICAMENTO') {
                my $principio = $item->{principio_activo}  // '';
                my $vence     = $item->{fecha_vencimiento} // '';
                $lista_med->insertar(int($codigo), $itnombre, $principio, $fab, $precio, $cant, $vence, $nivel);
                $resultado{exitosos}++;
                push @{$resultado{mensajes}}, "MED $codigo '$itnombre' insertado.";

            } elsif ($tipo eq 'EQUIPO') {
                my $fecha_ing = $item->{fecha_ingreso} // '';
                $bst->insertar(int($codigo), $itnombre, $fab, $precio, $cant, $fecha_ing, $nivel);
                $resultado{exitosos}++;
                push @{$resultado{mensajes}}, "EQU $codigo '$itnombre' insertado en BST.";

            } elsif ($tipo eq 'SUMINISTRO') {
                my $vence = $item->{fecha_vencimiento} // '';
                $arbol_b->insertar(int($codigo), $itnombre, $fab, $precio, $cant, $vence, $nivel);
                $resultado{exitosos}++;
                push @{$resultado{mensajes}}, "SUM $codigo '$itnombre' insertado en Arbol B.";

            } else {
                push @{$resultado{advertencias}}, "Tipo desconocido '$tipo' para codigo $codigo, se omite.";
                $resultado{errores}++;
                next;
            }

            $matriz->agregar($nit, $nombre, $fab, $cant) if $fab;
        }
    }
    return \%resultado;
}

sub cargar_usuarios {
    my ($ruta_archivo, $avl) = @_;
    my %resultado = (exitosos => 0, errores => 0, advertencias => [], mensajes => []);

    open(my $fh, '<:utf8', $ruta_archivo) or do {
        push @{$resultado{advertencias}}, "No se pudo abrir: $!";
        return \%resultado;
    };
    my $contenido = do { local $/; <$fh> };
    close($fh);

    my $datos;
    eval { $datos = decode_json($contenido); };
    if ($@) {
        push @{$resultado{advertencias}}, "Error al parsear JSON: $@";
        return \%resultado;
    }

    unless (ref($datos) eq 'HASH' && exists $datos->{usuarios}) {
        push @{$resultado{advertencias}}, "El JSON no tiene la clave 'usuarios'.";
        return \%resultado;
    }

    for my $u (@{$datos->{usuarios}}) {
        my $col  = $u->{numero_colegio}  // '';
        my $nom  = $u->{nombre_completo} // '';
        my $tipo = $u->{tipo_usuario}    // '';
        my $dep  = $u->{departamento}    // '';
        my $esp  = $u->{especialidad}    // '';
        my $pass = $u->{contrasena}      // '';

        unless ($col && $nom && $tipo && $dep) {
            push @{$resultado{advertencias}}, "Usuario sin datos completos (col=$col), se omite.";
            $resultado{errores}++;
            next;
        }
        if (defined $avl->buscar($col)) {
            push @{$resultado{advertencias}}, "Usuario $col ya existe en el AVL (ID duplicado), se omite.";
            $resultado{errores}++;
            next;
        }
        $avl->insertar($col, $nom, $tipo, $dep, $esp, $pass);
        $resultado{exitosos}++;
        push @{$resultado{mensajes}}, "Usuario $col '$nom' insertado en AVL.";
    }
    return \%resultado;
}

1;