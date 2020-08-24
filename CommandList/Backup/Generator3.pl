my @allinfogoals=(
                  [ 46, 0 ],
                  [ 45, 2 ],
                  [ 45, 0 ],
                  [ 33, 0 ],
                  [ 91, 0 ],
                  [ 90, 2 ],
                 );

@allinfogoals=sort { $a->[0] <=> $b->[0] || $a->[1] <=> $b->[1] } @allinfogoals;

use Data::Dump; dd \@allinfogoals;