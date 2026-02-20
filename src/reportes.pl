sub cargar_csv {
    my ($ruta) = @_;
    unless (-e $ruta) {
        print "\n  [!] El archivo '$ruta' no existe.\n";
        return;
    }

    open(my $fh, '<:utf8', $ruta) or do {
        print "\n  [!] No se pudo abrir '$ruta': $!\n";
        return;
    };

    my $num_linea  = 0;
    my $cargados   = 0;
    my $omitidos   = 0;
    my $duplicados = 0;

    while (my $linea = <$fh>) {
        chomp $linea;
        $num_linea++;

        next if ($num_linea == 1 && $linea =~ /^codigo/i);
        next if ($linea =~ /^\s*$/);

        my @c = split(/,/, $linea, -1);

        if (scalar(@c) < 8) {
            print "  [AVISO] Linea $num_linea omitida: campos insuficientes.\n";
            $omitidos++;
            next;
        }

        my ($codigo, $nombre, $pa, $lab, $precio, $cant, $fecha, $min) =
            map { _trim($_) } @c[0..7];

        unless ($precio =~ /^\d+(\.\d+)?$/) {
            print "  [AVISO] Linea $num_linea omitida: precio invalido.\n";
            $omitidos++;
            next;
        }

        unless ($cant =~ /^\d+$/ && $min =~ /^\d+$/) {
            print "  [AVISO] Linea $num_linea omitida: cantidad invalida.\n";
            $omitidos++;
            next;
        }

        if (defined buscar_nodo_inventario($codigo)) {
            $duplicados++;
            next;
        }

        insertar_medicamento($codigo, $nombre, $pa, $lab,
                             $precio+0, $cant+0, $fecha, $min+0);
        $cargados++;
    }

    close($fh);

    print "\n  Resumen de carga:\n";
    print "  - Registros insertados: $cargados\n";
    print "  - Duplicados omitidos:  $duplicados\n";
    print "  - Lineas con errores:   $omitidos\n";
}

sub cargar_csv_manual {
    print "\n--- Carga Masiva de Inventario desde CSV ---\n";
    print "  Ruta del archivo CSV: ";
    my $ruta = <STDIN>; chomp $ruta;
    if ($ruta eq "") {
        print "\n  [!] Debe ingresar una ruta valida.\n";
        return;
    }
    cargar_csv($ruta);
}

sub _trim {
    my ($s) = @_;
    $s =~ s/^\s+|\s+$//g;
    return $s;
}

1;