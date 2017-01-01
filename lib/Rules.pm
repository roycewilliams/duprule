# (c) mhasbini 2016
package Rules;
use strict;
# use warnings;
use warnings FATAL => 'all';
use vars qw($VERSION);
use Data::Dumper;
use Storable 'dclone';
use Utils;

$VERSION = '0.01';
$Data::Dumper::Sortkeys = 1;

sub new {
	my $class = shift;
	my %parm  = @_;
	my $this  = {};
	bless $this, $class;
	$this->{verbose} = $parm{verbose} || 0;
	$this->{magic} = $parm{magic} || 36; # 0-9 + A-Z + 1
	# $this->{element}{0} = {}
	$this->{rules} = {
	# General
	':'	=> sub {
			my @rule_ref = @{ shift; };
			splice( @rule_ref, 0, 1 );
			return \@rule_ref;
		},
	' '	=> sub {
			my @rule_ref = @{ shift; };
			splice( @rule_ref, 0, 1 );
			$this->{function_count}--;
			return \@rule_ref;
		},
	'l' => sub {
			my @rule_ref = @{ shift; };
			splice( @rule_ref, 0, 1 );
			my $largest_pos = &largest_pos( $this->{status}->{pos} );
			$this->{status}->{pos}{$_}->{case} = 'l' for 0 .. $largest_pos;
			return \@rule_ref;
		},
	'u' => sub {
			my @rule_ref = @{ shift; };
			splice( @rule_ref, 0, 1 );
			my $largest_pos = &largest_pos( $this->{status}->{pos} );
			return \@rule_ref if $largest_pos == -1;
			$this->{status}->{pos}{$_}->{case} = 'u' for 0 .. $largest_pos;
			return \@rule_ref;
		},
	'c' => sub {
			my @rule_ref = @{ shift; };
			splice( @rule_ref, 0, 1 );
			my $largest_pos = &largest_pos( $this->{status}->{pos} );
			return \@rule_ref if $largest_pos == -1;
			$this->{status}->{pos}{0}->{case} = 'u';
			$this->{status}->{pos}{$_}->{case} = 'l' for 1 .. $largest_pos;
			return \@rule_ref;
		},
	'C' => sub {
			my @rule_ref = @{ shift; };
			splice( @rule_ref, 0, 1 );
			my $largest_pos = &largest_pos( $this->{status}->{pos} );
			return \@rule_ref if $largest_pos == -1;
			$this->{status}->{pos}{0}->{case} = 'l';
			for (1 .. $largest_pos) {
				if(exists($this->{status}->{pos}{$_})) {
					$this->{status}->{pos}{$_}->{case} = 'u';
				}
			}
			return \@rule_ref;
		},
	'r' => sub {
			my @rule_ref = @{ shift; };
			splice( @rule_ref, 0, 1 );
			my $largest_pos = &largest_pos( $this->{status}->{pos} );
			return \@rule_ref if $largest_pos == -1;
			my $temp;
			for (0 .. $largest_pos) {
				$temp->{status}->{pos}{$_} = dclone $this->{status}->{pos}{$largest_pos - $_};
			}
			$this->{status}->{pos} = dclone $temp->{status}->{pos};
			return \@rule_ref;
		},
	't' => sub {
			my @rule_ref = @{ shift; };
			splice( @rule_ref, 0, 1 );
			my $largest_pos = &largest_pos( $this->{status}->{pos} );
			return \@rule_ref if $largest_pos == -1;
			for (0 .. $largest_pos) {
				my $case = $this->{status}->{pos}{$_}->{case};
				$this->{status}->{pos}{$_}->{case} = $case eq 'd' ? 'b' : $case eq 'b' ? 'd' : $case eq 'l' ? 'u' : 'l';
			}
			return \@rule_ref;
		},
	'T' => sub {
			my @rule_ref = @{ shift; };
			my $pos = &to_pos( $rule_ref[1] );
			splice( @rule_ref, 0, 2 );
			if(exists($this->{status}->{pos}{$pos})) {
				my $case = $this->{status}->{pos}{$pos}->{case};
				$this->{status}->{pos}{$pos}->{case} = $case eq 'd' ? 'b' : $case eq 'b' ? 'd' : $case eq 'l' ? 'u' : 'l';
			}
			return \@rule_ref;
		},
	'd' => sub {
			my @rule_ref = @{ shift; };
			splice( @rule_ref, 0, 1 );
			my $largest_pos = &largest_pos( $this->{status}->{pos} );
			for (0 .. $largest_pos) {
				$this->{status}->{pos}{$largest_pos + 1 + $_} = dclone $this->{status}->{pos}{$_};
			}
			return \@rule_ref;
		},
	'p' => sub {
			my @rule_ref = @{ shift; };
			my $n = &to_pos( $rule_ref[1] );
			splice( @rule_ref, 0, 2 );
			for (0 .. $n) {
				my $largest_pos = &largest_pos( $this->{status}->{pos} );
				foreach my $pos (0 .. $largest_pos) {
					$this->{status}->{pos}{$largest_pos + 1 + $pos} = dclone $this->{status}->{pos}{$pos};
				}
			}
			return \@rule_ref;
		},
	'f' => sub {
			my @rule_ref = @{ shift; };
			splice( @rule_ref, 0, 1 );
			my $largest_pos = &largest_pos( $this->{status}->{pos} );
			return \@rule_ref if $largest_pos == -1;
			for (0 .. $largest_pos) {
				$this->{status}->{pos}{$largest_pos + 1 + $_} = dclone $this->{status}->{pos}{$largest_pos - $_};
			}
			return \@rule_ref;
		},
	'{' => sub {
			my @rule_ref = @{ shift; };
			splice( @rule_ref, 0, 1 );
			my $largest_pos = &largest_pos( $this->{status}->{pos} );
			return \@rule_ref if $largest_pos == -1;
			my $temp = dclone $this->{status}->{pos}{0};
			for (1 .. $largest_pos) {
				$this->{status}->{pos}{$_ - 1} = delete $this->{status}->{pos}{$_};
			}
			$this->{status}->{pos}{$largest_pos} = dclone $temp;
			return \@rule_ref;
		},
	'}' => sub {
			my @rule_ref = @{ shift; };
			splice( @rule_ref, 0, 1 );
			my $largest_pos = &largest_pos( $this->{status}->{pos} );
			return \@rule_ref if $largest_pos == -1;
			my $temp = dclone $this->{status}->{pos}{$largest_pos};
			for (reverse 0 .. $largest_pos - 1) {
				if(exists($this->{status}->{pos}{$_})) {
					$this->{status}->{pos}{$_ + 1} = dclone $this->{status}->{pos}{$_};
				}
			}
			$this->{status}->{pos}{0} = dclone $temp;
			return \@rule_ref;
		},
	'$' => sub {
			my @rule_ref = @{ shift; };
			my $char = $rule_ref[1];
			splice( @rule_ref, 0, 2 );
			my $largest_pos = &largest_pos( $this->{status}->{pos} );
			return \@rule_ref if $largest_pos == -1;
			$this->{status}->{pos}{$largest_pos + 1}->{value} = lc($char);
			$this->{status}->{pos}{$largest_pos + 1}->{element} = -1;
			$this->{status}->{pos}{$largest_pos + 1}->{case} = &get_case( $char );
			$this->{status}->{pos}{$largest_pos + 1}->{bitwize_shift} = 0;
			$this->{status}->{pos}{$largest_pos + 1}->{ascii_shift} = 0;
			return \@rule_ref;
		},
	'^' => sub {
			my @rule_ref = @{ shift; };
			my $char = $rule_ref[1];
			splice( @rule_ref, 0, 2 );
			my $largest_pos = &largest_pos( $this->{status}->{pos} );
			return \@rule_ref if $largest_pos == -1;
			for (reverse 0 .. $largest_pos)	{
				$this->{status}->{pos}{$_ + 1} = dclone $this->{status}->{pos}{$_};
			}
			$this->{status}->{pos}{0}->{value} = lc($char);
			$this->{status}->{pos}{0}->{element} = -1;
			$this->{status}->{pos}{0}->{case} = &get_case( $char );
			$this->{status}->{pos}{0}->{bitwize_shift} = 0;
			$this->{status}->{pos}{0}->{ascii_shift} = 0;
			return \@rule_ref;
		},
	'[' => sub {
			my @rule_ref = @{ shift; };
			splice( @rule_ref, 0, 1 );
			my $largest_pos = &largest_pos( $this->{status}->{pos} );
			return \@rule_ref if $largest_pos == -1;
			delete $this->{status}->{pos}{0}; # delete first element
			# backward positions by 1
			for (1 .. $largest_pos) {
				$this->{status}->{pos}{$_ - 1} = delete $this->{status}->{pos}{$_};
			}
			return \@rule_ref;
		},
	']' => sub {
			my @rule_ref = @{ shift; };
			splice( @rule_ref, 0, 1 );
			my $largest_pos = &largest_pos( $this->{status}->{pos} );
			return \@rule_ref if $largest_pos == -1;
			delete $this->{status}->{pos}{$largest_pos}; # delete last element
			return \@rule_ref;
		},
	'D' => sub {
			my @rule_ref = @{ shift; };
			my $n = &to_pos( $rule_ref[1] );
			splice( @rule_ref, 0, 2 );
			my $largest_pos = &largest_pos( $this->{status}->{pos} );
			return \@rule_ref if $largest_pos == -1;
			delete $this->{status}->{pos}{$n}; # delete element at position $n
			# backward positions by 1 after $n
			for ($n + 1 .. $largest_pos) {
				$this->{status}->{pos}{$_ - 1} = delete $this->{status}->{pos}{$_};
			}
			return \@rule_ref;
		},
	'x' => sub {
			my @rule_ref = @{ shift; };
			my $n = &to_pos( $rule_ref[1] );
			my $m = &to_pos( $rule_ref[2] );
			splice( @rule_ref, 0, 3 );
			my $largest_pos = &largest_pos( $this->{status}->{pos} );
			return \@rule_ref if $largest_pos == -1;
			delete $this->{status}->{pos}{$_} for $m + $n .. $largest_pos; # delete element after $m
			delete $this->{status}->{pos}{$_} for 0 .. $n - 1; # delete element before $n
			# backward positions by $n
			for ($n .. $n + $m - 1) {
				if(exists($this->{status}->{pos}{$_})) {
					$this->{status}->{pos}{$_ - $n} = delete $this->{status}->{pos}{$_};
				}
			}
			return \@rule_ref;
		},
	'O' => sub {
			my @rule_ref = @{ shift; };
			my $n = &to_pos( $rule_ref[1] );
			my $m = &to_pos( $rule_ref[2] );
			splice( @rule_ref, 0, 3 );
			my $largest_pos = &largest_pos( $this->{status}->{pos} );
			return \@rule_ref if $largest_pos == -1;
			delete $this->{status}->{pos}{$_} for $n .. $n + $m - 1; # delete range $n -> $m
			# backward positions
 			for ($n + $m .. $largest_pos) {
				$this->{status}->{pos}{$_ - $m} = delete $this->{status}->{pos}{$_};
			}
			return \@rule_ref;
		},
	'i' => sub {
			my @rule_ref = @{ shift; };
			my $n = &to_pos( $rule_ref[1] );
			my $char = $rule_ref[2];
			splice( @rule_ref, 0, 3 );
			my $largest_pos = &largest_pos( $this->{status}->{pos} );
			return \@rule_ref if $largest_pos == -1;
			# forwarding positions by 1
 			for (reverse $n .. $largest_pos) {
				$this->{status}->{pos}{$_ + 1} = delete $this->{status}->{pos}{$_};
			}
			if($n <= $largest_pos + 1) {
				$this->{status}->{pos}{$n}->{value} = lc($char);
				$this->{status}->{pos}{$n}->{element} = -1;
				$this->{status}->{pos}{$n}->{case} = &get_case( $char );
				$this->{status}->{pos}{$n}->{bitwize_shift} = 0;
				$this->{status}->{pos}{$n}->{ascii_shift} = 0;
			}
			return \@rule_ref;
		},
	'o' => sub {
			my @rule_ref = @{ shift; };
			my $n = &to_pos( $rule_ref[1] );
			my $char = $rule_ref[2];
			splice( @rule_ref, 0, 3 );
			return \@rule_ref if &largest_pos( $this->{status}->{pos} ) == -1;
			if(exists($this->{status}->{pos}{$n})) {
				$this->{status}->{pos}{$n}->{value} = lc($char);
				$this->{status}->{pos}{$n}->{element} = -1;
				$this->{status}->{pos}{$n}->{case} = &get_case( $char );
				$this->{status}->{pos}{$n}->{bitwize_shift} = 0;
				$this->{status}->{pos}{$n}->{ascii_shift} = 0;
			}
			return \@rule_ref;
		},
	"'" => sub {
			my @rule_ref = @{ shift; };
			my $n = &to_pos( $rule_ref[1] );
			splice( @rule_ref, 0, 2 );
			my $largest_pos = &largest_pos( $this->{status}->{pos} );
			return \@rule_ref if $largest_pos == -1;
			delete $this->{status}->{pos}{$_} for $n .. $largest_pos; # delete range $n -> last
			return \@rule_ref;
		},
	's' => sub {
			my @rule_ref = @{ shift; };
			my $char = $rule_ref[1];
			my $replaced_char = $rule_ref[2];
			splice( @rule_ref, 0, 3 );
			return \@rule_ref if $char eq $replaced_char; # change nothing if trying to replace character by itself
			return \@rule_ref if defined $this->{status}->{substitution}{$char} && $this->{status}->{substitution}{$char} eq ''; # if a character was deleted before, it shouldn't be replaced because it doesn't exists.
			$this->{status}->{substitution}{$char} = $replaced_char;
			my $largest_pos = &largest_pos( $this->{status}->{pos} );
			return \@rule_ref if $largest_pos == -1;
			for (0 .. $largest_pos) {
				if(exists($this->{status}->{pos}{$_})) {
					if ($this->{status}->{pos}{$_}->{value} eq $char) {
						$this->{status}->{pos}{$_}->{value} = $replaced_char;
						$this->{status}->{pos}{$_}->{element} = -1;
						$this->{status}->{pos}{$_}->{case} = &get_case( $replaced_char );
						$this->{status}->{pos}{$_}->{bitwize_shift} = 0;
						$this->{status}->{pos}{$_}->{ascii_shift} = 0;
					}
				}
			}
			return \@rule_ref;
		},
		'@' => sub {
				my @rule_ref = @{ shift; };
				my $char = $rule_ref[1];
				splice( @rule_ref, 0, 2 );
				# replace $char with '' ( blank )
				my $replaced_char = '';
				# if a character is replaced by $char, it should be replace by ''
				if(defined $this->{status}->{substitution}) {
					my $tmp = dclone $this->{status}->{substitution};
				 	while (my ($key, $replaced_by) = each %{$tmp}) {
						if($replaced_by eq $char) {
							$this->{status}->{substitution}{$key} = $replaced_char;
						}
					}
				}
				$this->{status}->{substitution}{$char} = $replaced_char;
				my $largest_pos = &largest_pos( $this->{status}->{pos} );
				return \@rule_ref if $largest_pos == -1;
				foreach my $pos (0 .. $largest_pos) {
					if(exists($this->{status}->{pos}{$pos}) && $this->{status}->{pos}{$pos}->{value} eq $char) {
						for ($pos + 1 .. $largest_pos) {
							$this->{status}->{pos}{$_ - 1} = delete $this->{status}->{pos}{$_};
						}
					}
				}
				return \@rule_ref;
	},
	'z' => sub {
			my @rule_ref = @{ shift; };
			my $n = &to_pos( $rule_ref[1] );
			splice( @rule_ref, 0, 2 );
			my $largest_pos = &largest_pos( $this->{status}->{pos} );
			return \@rule_ref if $largest_pos == -1;
			# forward positions by $n
			for (reverse 1 .. $largest_pos) {
				$this->{status}->{pos}{$_ + $n} = delete $this->{status}->{pos}{$_};
			}
			# duplicate first char
			if(exists($this->{status}->{pos}{0})) {
				for (1 .. $n) {
					$this->{status}->{pos}{$_} = dclone $this->{status}->{pos}{0};
				}
			}
			return \@rule_ref;
		},
	'Z' => sub {
			my @rule_ref = @{ shift; };
			my $n = &to_pos( $rule_ref[1] );
			splice( @rule_ref, 0, 2 );
			my $largest_pos = &largest_pos( $this->{status}->{pos} );
			return \@rule_ref if $largest_pos == -1;
			# duplicate first char
			if(exists($this->{status}->{pos}{$largest_pos})) {
				for ($largest_pos + 1 .. $largest_pos + $n) {
					$this->{status}->{pos}{$_} = dclone $this->{status}->{pos}{$largest_pos};
				}
			}
			return \@rule_ref;
		},
	'q' => sub {
			my @rule_ref = @{ shift; };
			splice( @rule_ref, 0, 1 );
			my $largest_pos = &largest_pos( $this->{status}->{pos} );
			return \@rule_ref if $largest_pos == -1;
			for (reverse 0 .. $largest_pos) {
				$this->{status}->{pos}{$_ + $_ + 1} = dclone $this->{status}->{pos}{$_};
				$this->{status}->{pos}{$_ + $_} = dclone $this->{status}->{pos}{$_};
			}
			return \@rule_ref;
		},

	# Specific
	'k' => sub {
			my @rule_ref = @{ shift; };
			splice( @rule_ref, 0, 1 );
			return \@rule_ref if &largest_pos( $this->{status}->{pos} ) == -1;
			if(exists($this->{status}->{pos}{0}) && exists($this->{status}->{pos}{1})) {
				($this->{status}->{pos}{0}, $this->{status}->{pos}{1}) = ($this->{status}->{pos}{1}, $this->{status}->{pos}{0});
			}
			return \@rule_ref;
		},
	'K' => sub {
			my @rule_ref = @{ shift; };
			splice( @rule_ref, 0, 1 );
			my $largest_pos = &largest_pos( $this->{status}->{pos} );
			return \@rule_ref if $largest_pos == -1;
			if(exists($this->{status}->{pos}{$largest_pos}) && exists($this->{status}->{pos}{$largest_pos - 1})) {
				($this->{status}->{pos}{$largest_pos}, $this->{status}->{pos}{$largest_pos - 1}) = ($this->{status}->{pos}{$largest_pos - 1}, $this->{status}->{pos}{$largest_pos});
			}
			return \@rule_ref;
		},
	'*' => sub {
			my @rule_ref = @{ shift; };
			my $n = &to_pos( $rule_ref[1] );
			my $m = &to_pos( $rule_ref[2] );
			splice( @rule_ref, 0, 3 );
			return \@rule_ref if &largest_pos( $this->{status}->{pos} ) == -1;
			if(exists($this->{status}->{pos}{$n}) && exists($this->{status}->{pos}{$m})) {
				($this->{status}->{pos}{$n}, $this->{status}->{pos}{$m}) = ($this->{status}->{pos}{$m}, $this->{status}->{pos}{$n});
			}
			return \@rule_ref;
		},
	'L' => sub {
			my @rule_ref = @{ shift; };
			my $n = &to_pos( $rule_ref[1] );
			splice( @rule_ref, 0, 2 );
			return \@rule_ref if &largest_pos( $this->{status}->{pos} ) == -1;
			if(exists($this->{status}->{pos}{$n})) {
				if($this->{status}->{pos}{$n}->{value} eq '') {
					$this->{status}->{pos}{$n}->{bitwize_shift}++;
				} else {
					$this->{status}->{pos}{$n}->{value} = chr( ord( $this->{status}->{pos}{$n}->{value} ) << 1 );
				}
			}
			return \@rule_ref;
		},
	'R' => sub {
			my @rule_ref = @{ shift; };
			my $n = &to_pos( $rule_ref[1] );
			splice( @rule_ref, 0, 2 );
			return \@rule_ref if &largest_pos( $this->{status}->{pos} ) == -1;
			if(exists($this->{status}->{pos}{$n})) {
				if($this->{status}->{pos}{$n}->{value} eq '') {
					$this->{status}->{pos}{$n}->{bitwize_shift}--;
				} else {
					$this->{status}->{pos}{$n}->{value} = chr( ord( $this->{status}->{pos}{$n}->{value} ) >> 1 );
				}
			}
			return \@rule_ref;
		},
	'+' => sub {
			my @rule_ref = @{ shift; };
			my $n = &to_pos( $rule_ref[1] );
			splice( @rule_ref, 0, 2 );
			return \@rule_ref if &largest_pos( $this->{status}->{pos} ) == -1;
			if(exists($this->{status}->{pos}{$n})) {
				if($this->{status}->{pos}{$n}->{value} eq '') {
					$this->{status}->{pos}{$n}->{ascii_shift}++;
				} else {
					$this->{status}->{pos}{$n}->{value} = chr( ord( $this->{status}->{pos}{$n}->{value} ) + 1 );
				}
			}
			return \@rule_ref;
		},
	'-' => sub {
			my @rule_ref = @{ shift; };
			my $n = &to_pos( $rule_ref[1] );
			splice( @rule_ref, 0, 2 );
			return \@rule_ref if &largest_pos( $this->{status}->{pos} ) == -1;
			if(exists($this->{status}->{pos}{$n})) {
				if($this->{status}->{pos}{$n}->{value} eq '') {
					$this->{status}->{pos}{$n}->{ascii_shift}--;
				} else {
					$this->{status}->{pos}{$n}->{value} = chr( ord( $this->{status}->{pos}{$n}->{value} ) - 1 );
				}
			}
			return \@rule_ref;
		},
	'.' => sub {
			my @rule_ref = @{ shift; };
			my $n = &to_pos( $rule_ref[1] );
			splice( @rule_ref, 0, 2 );
			my $largest_pos = &largest_pos( $this->{status}->{pos} );
			return \@rule_ref if $largest_pos == -1;
			if(exists($this->{status}->{pos}{$n}) && exists($this->{status}->{pos}{$n + 1})) {
				$this->{status}->{pos}{$n} = dclone $this->{status}->{pos}{$n + 1};
			}
			return \@rule_ref;
		},
	',' => sub {
			my @rule_ref = @{ shift; };
			my $n = &to_pos( $rule_ref[1] );
			splice( @rule_ref, 0, 2 );
			return \@rule_ref if &largest_pos( $this->{status}->{pos} ) == -1;
			if(exists($this->{status}->{pos}{$n}) && exists($this->{status}->{pos}{$n - 1})) {
				$this->{status}->{pos}{$n} = dclone $this->{status}->{pos}{$n - 1};
			}
			return \@rule_ref;
		},
	'y' => sub {
			my @rule_ref = @{ shift; };
			my $n = &to_pos( $rule_ref[1] );
			splice( @rule_ref, 0, 2 );
			my $largest_pos = &largest_pos( $this->{status}->{pos} );
			return \@rule_ref if $largest_pos == -1;
			return \@rule_ref if $n > $largest_pos + 1;
			# forward all positions by $n
			for (reverse 0 .. $largest_pos) {
				if(exists($this->{status}->{pos}{$_})) {
					$this->{status}->{pos}{$_ + $n} = delete $this->{status}->{pos}{$_};
				}
			}
			for (0 .. $n - 1) {
				if(exists($this->{status}->{pos}{$_ + $n})) {
					$this->{status}->{pos}{$_} = dclone $this->{status}->{pos}{$_ + $n};
				}
			}
			return \@rule_ref;
		},
	'Y' => sub {
			my @rule_ref = @{ shift; };
			my $n = &to_pos( $rule_ref[1] );
			splice( @rule_ref, 0, 2 );
			my $largest_pos = &largest_pos( $this->{status}->{pos} );
			return \@rule_ref if $largest_pos == -1;
			return \@rule_ref if $n > $largest_pos + 1;
			for (reverse $largest_pos - $n + 1 .. $largest_pos) {
				if(exists($this->{status}->{pos}{$_})) {
					$this->{status}->{pos}{$_ + $n} = dclone $this->{status}->{pos}{$_};
				}
			}
			return \@rule_ref;
		},

	};
	return $this;
}

sub proccess {
	my $self = shift;
	my $rule = shift;
	my @return;
	my $i = 0;
	foreach my $magic (0 .. $self->{magic}) {
		$self->{function_count} = 0;
		# initialize
		$self->{status}->{pos}{$_}->{case} = 'd' for 0 .. $magic;
		$self->{status}->{pos}{$_}->{element} = $_ + 1 for 0 .. $magic;
		$self->{status}->{pos}{$_}->{value} = '' for 0 .. $magic;
		$self->{status}->{pos}{$_}->{bitwize_shift} = 0 for 0 .. $magic; # left -> + | right -> -
		$self->{status}->{pos}{$_}->{ascii_shift} = 0 for 0 .. $magic;
		# $self->{status}->{substitution};
		$self->{last_element} = $magic + 1; # used when inserting new elements to keep counting.
		# finish initialization
		my $rule_ref = [ split '', $rule ];
		while (1) {
			last if !@{$rule_ref}[0];
			print "Executing @{$rule_ref}[0]: \n" if $self->{verbose};
			$rule_ref =	$self->{rules}->{ @{$rule_ref}[0] }->( $rule_ref );
			$self->{function_count}++;
			print Dumper $self->{status} if $self->{verbose};
		}
		$return[$i++] = $self->{status};
		$self->{status} = undef;
	}
	return wantarray() ? (\@return, $self->{function_count}) : \@return;
};

sub to_pos {
	my $pos = $_[0];
	if ( $pos =~ /\d/ ) { return $pos; }
	return 10 + ord($pos) - 65;
}

sub largest_pos {
	my $hash   = shift;
	my @keys = keys %$hash;
	my $max = -1;
	foreach my $key (0 .. $#keys) {
		$max = $keys[$key] if $keys[$key] > $max;
	}
	return $max;
}

sub get_case {
	my $char = shift; # length = 1
	return lc($char) eq $char ? 'l' : 'u';
}

1;