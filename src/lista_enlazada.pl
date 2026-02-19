our $lista_historial = undef;

sub registrar_historial {
    my ($tipo, $codigo, $nombre, $cantidad) = @_;
    
    my @t    = localtime(time);
    my $ts   = sprintf("%04d-%02d-%02d %02d:%02d:%02d",
                 $t[5]+1900, $t[4]+1, $t[3], $t[2], $t[1], $t[0]);

    my $nodo = {
        tipo_operacion => $tipo,
        codigo         => $codigo,
        nombre         => $nombre,
        cantidad       => $cantidad,
        fecha_hora     => $ts,
        sig            => undef,
    };

    $nodo->{sig}     = $lista_historial;
    $lista_historial = $nodo;
}

sub mostrar_historial {
    if (!defined $lista_historial) {
        print "\n  [INFO] No hay movimientos registrados aun.\n";
        return;
    }
    
    print "\n" . "=" x 70 . "\n";
    print "  HISTORIAL DE MOVIMIENTOS DEL INVENTARIO\n";
    print "=" x 70 . "\n";
    printf "  %-18s %-8s %-18s %6s  %-19s\n",
         "Tipo Operacion", "Codigo", "Medicamento", "Cant", "Fecha y Hora";
    print "-" x 70 . "\n";

    my $actual = $lista_historial;
    while (defined $actual) {
        printf "  %-18s %-8s %-18s %6d  %-19s\n",
            $actual->{tipo_operacion},
            $actual->{codigo},
            $actual->{nombre},
            $actual->{cantidad},
            $actual->{fecha_hora};
        $actual = $actual->{sig};
    }
    print "=" x 70 . "\n";
}

1;