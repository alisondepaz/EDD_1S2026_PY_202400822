our $cabecera_filas = undef;
our $cabecera_cols  = undef;

sub obtener_cabecera_fila {
    my ($nombre) = @_;
    my $actual = $cabecera_filas;
    while (defined $actual) {
        return $actual if (lc($actual->{nombre}) eq lc($nombre));
        $actual = $actual->{sig_fila};
    }
    
    my $nueva = {
        nombre      => $nombre,
        sig_fila    => undef,
        primer_nodo => undef,
    };

    if (!defined $cabecera_filas) {
        $cabecera_filas = $nueva;
    } else {
        my $ult = $cabecera_filas;
        while (defined $ult->{sig_fila}) { $ult = $ult->{sig_fila}; }
        $ult->{sig_fila} = $nueva;
    }
    return $nueva;
}

sub obtener_cabecera_col {
    my ($nombre) = @_;
    my $actual = $cabecera_cols;
    while (defined $actual) {
        return $actual if (lc($actual->{nombre}) eq lc($nombre));
        $actual = $actual->{sig_col};
    }
    
    my $nueva = {
        nombre      => $nombre,
        sig_col     => undef,
        primer_nodo => undef,
    };

    if (!defined $cabecera_cols) {
        $cabecera_cols = $nueva;
    } else {
        my $ult = $cabecera_cols;
        while (defined $ult->{sig_col}) { $ult = $ult->{sig_col}; }
        $ult->{sig_col} = $nueva;
    }
    return $nueva;
}

sub actualizar_matriz_precio {
    my ($laboratorio, $medicamento, $precio, $principio_activo, $cantidad) = @_;
    return if (!defined $laboratorio || $laboratorio eq "");
    return if (!defined $medicamento  || $medicamento  eq "");
    
    my $fila = obtener_cabecera_fila($laboratorio);
    my $col  = obtener_cabecera_col($medicamento);
    
    my $actual = $fila->{primer_nodo};
    while (defined $actual) {
        if (lc($actual->{medicamento}) eq lc($medicamento)) {
            $actual->{precio}           = $precio;
            $actual->{cantidad}         = $cantidad;
            $actual->{principio_activo} = $principio_activo;
            return;
        }
        $actual = $actual->{sig_fila};
    }
    
    my $nodo = {
        laboratorio      => $laboratorio,
        medicamento      => $medicamento,
        precio           => $precio,
        principio_activo => $principio_activo,
        cantidad         => $cantidad,
        sig_fila         => undef,
        sig_col          => undef,
    };
    
    if (!defined $fila->{primer_nodo}) {
        $fila->{primer_nodo} = $nodo;
    } else {
        my $ult = $fila->{primer_nodo};
        while (defined $ult->{sig_fila}) { $ult = $ult->{sig_fila}; }
        $ult->{sig_fila} = $nodo;
    }
    
    if (!defined $col->{primer_nodo}) {
        $col->{primer_nodo} = $nodo;
    } else {
        my $ult = $col->{primer_nodo};
        while (defined $ult->{sig_col}) { $ult = $ult->{sig_col}; }
        $ult->{sig_col} = $nodo;
    }
}

sub consultar_por_medicamento {
    my ($nombre_med) = @_;
    unless (defined $cabecera_cols) {
        print "\n  [!] La matriz esta vacia.\n";
        return;
    }
    
    my $col = $cabecera_cols;
    while (defined $col) {
        last if (lc($col->{nombre}) eq lc($nombre_med));
        $col = $col->{sig_col};
    }
    
    unless (defined $col) {
        print "\n  [!] No se encontro el medicamento '$nombre_med'.\n";
        return;
    }
    
    print "\n" . "=" x 70 . "\n";
    print "  MEDICAMENTO: $nombre_med\n";
    print "=" x 70 . "\n";
    printf "  %-25s %10s %15s\n", "Laboratorio", "Precio (Q)", "Stock";
    print "-" x 70 . "\n";
    
    my $nodo = $col->{primer_nodo};
    my $count = 0;
    while (defined $nodo) {
        printf "  %-25s %10.2f %15d\n", 
            $nodo->{laboratorio}, $nodo->{precio}, $nodo->{cantidad};
        $count++;
        $nodo = $nodo->{sig_col};
    }
    
    print "=" x 70 . "\n";
    print "  Total: $count laboratorio(s) fabrican este medicamento\n";
}

sub consultar_por_laboratorio {
    my ($nombre_lab) = @_;
    unless (defined $cabecera_filas) {
        print "\n  [!] La matriz esta vacia.\n";
        return;
    }
    
    my $fila = $cabecera_filas;
    while (defined $fila) {
        last if (lc($fila->{nombre}) eq lc($nombre_lab));
        $fila = $fila->{sig_fila};
    }
    
    unless (defined $fila) {
        print "\n  [!] No se encontro el laboratorio '$nombre_lab'.\n";
        return;
    }
    
    print "\n" . "=" x 70 . "\n";
    print "  LABORATORIO: $nombre_lab\n";
    print "=" x 70 . "\n";
    printf "  %-25s %10s %15s\n", "Medicamento", "Precio (Q)", "Stock";
    print "-" x 70 . "\n";
    
    my $nodo = $fila->{primer_nodo};
    my $count = 0;
    while (defined $nodo) {
        printf "  %-25s %10.2f %15d\n", 
            $nodo->{medicamento}, $nodo->{precio}, $nodo->{cantidad};
        $count++;
        $nodo = $nodo->{sig_fila};
    }
    
    print "=" x 70 . "\n";
    print "  Total: $count medicamento(s) de este laboratorio\n";
}

1;