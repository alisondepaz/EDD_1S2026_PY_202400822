sub pausar {
    print "\n  Presione ENTER para continuar...";
    <STDIN>;
}

sub fecha_hoy {
    my @t = localtime(time);
    return sprintf("%04d-%02d-%02d", $t[5]+1900, $t[4]+1, $t[3]);
}

sub validar_fecha {
    my ($f) = @_;
    return ($f =~ /^\d{4}-(0[1-9]|1[0-2])-(0[1-9]|[12]\d|3[01])$/);
}

sub linea {
    my ($car, $n) = @_;
    $car //= "-"; 
    $n //= 50;
    print $car x $n . "\n";
}

1;