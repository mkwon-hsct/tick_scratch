// polyadic_func.q

/
* @brief Sums up all argumants 
* @param a1: some number
* @type
* - (list of) long
* - (list of) float
* @param a2: some number
* @type
* - (list of) long
* - (list of) float
* @param a3: some number
* @type
* - (list of) long
* - (list of) float
* @param a4: some number
* @type
* - (list of) long
* - (list of) float
* @return
* - (list of) long IF all arguments are long
* - (ist of) float IF any argument is float
\
sum_all:{[a1;a2;a3;a4]
  a1+:a2;
  a1+:a3;
  a1+a4
 };

// func[arg_1; arg_2; ...; arg_n]
-1!"Do: sum_all[10; 20; 30; 40]";
a:sum_all[10; 20; 30; 40];
show a;

// func . (arg_1; arg_2; ...; arg_n) 
-1!"Do: sum_all . (10; 20; 30; 40)";
a:sum_all . (10; 20; 30; 40);
show a;

// Since . is a dyadic function, we can use "each-right" with it
// flip will converts shape from 4*2 into 2*4
-1"Do: sum_all ./: flip (10 20; 30 40; 50 60; 70 80)";
a:sum_all ./: flip (10 20; 30 40; 50 60; 70 80);
show a;

// Error trap
// .[func; (arg_1; arg_2; ...; arg_n); catch_func]
// Returns a tuple of (error indicator; error message)
-1"Do: .[sum_all; (10; 20; `30; 40); {[err] (1b; `$err)}]";
a:.[sum_all; (10; 20; `30; 40); {[err] (1b; `$err)}];
show a;