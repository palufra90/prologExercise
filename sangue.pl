%aggiunte compatibilita' per 4 gruppi, modificati nomi e qualche commento
%modificato output in modo che dia due liste e costo, o messaggio di impossibilita'
%aggiunto scambio compatibile tra ospedali
%modificato output in modo da visualizzare costo minore
%corretto interChange, che non funzionava se rimanevano irrisolte piu' necessita'
%aggiunti imput costo trasferimento e costo unitario
%aggiunta distinzione tra gruppi RH+ e RH-

%per disabilitare abbreviazioni, scrivere: 
% set_prolog_flag(toplevel_print_options,[quoted(true), portray(true)]).
%input: necessita' e disponibilita', costo trasferimento e costo unitario
%output: sangue trasferito da ogni centro, costo finale

%blood([1,1,1,1,0,0,0,0],[1,1,1,1,0,0,0,0],[2,2,2,2,0,0,0,0],[2,2,2,2,0,0,0,0],1,1,L).
%blood([1,4,1,2,0,0,0,0],[2,0,1,0,0,0,0,0],[2,3,2,2,0,0,0,0],[3,1,0,1,0,0,0,0],3,1,L).
%blood([0,0,0,0,0,0,0,0],[0,0,0,1,0,0,0,0],[1,1,1,3,0,0,0,0],[0,2,0,0,0,0,0,0],2,1,L).
%blood([1,2,1,0,0,0,0,0],[0,0,0,1,0,0,0,0],[1,1,1,3,0,0,0,0],[0,2,0,0,0,0,0,0],3,2,L).
%blood([1,2,1,3,0,0,0,0],[1,0,4,1,0,0,0,0],[2,1,1,3,0,0,0,0],[0,2,3,2,0,0,0,0],1,1,L).
%blood([3,0,0,0,1,1,0,0],[0,0,0,1,0,0,2,0],[0,1,0,1,0,0,0,0],[1,0,0,5,0,0,0,0],3,2,L).
%blood([3,0,0,0,1,1,0,0],[0,0,0,1,0,0,2,0],[0,1,0,1,1,0,0,0],[1,0,0,3,0,0,0,1],3,2,L).

%Ct= costo trasferimento
%Cu= costo unita' trasferita
blood(Necc1,Necc2,Disp1,Disp2,Ct,Cu,Min):-
	findall(X,(blood1(Necc1,Necc2,Disp1,Disp2,Ct,Cu,X),
			   X\=['Impossibile eseguire lo scambio di sacche tra ospedali',[],'Inf']),L),
	list_min(L,Min).

blood1(Necc1,Necc2,Disp1,Disp2,Ct,Cu,Z):- 	
	interChange(Disp1,Necc1,0,[],E1),		%E1 contiene le nuove necessita' e disponibilita' 
											%dopo aver fatto gli scambi interni tra gruppi compatibili
											%(quindi rap. le richieste da fare all'altro ospedale) 	E1=[Necc1,Disp1]
	interChange(Disp2,Necc2,0,[],E2),		%E2 contiene le nuove necessita' e disponibilita' 
											%dopo aver fatto gli scambi interni tra gruppi compatibili
											%(quindi rap. le richieste da fare all'altro ospedale)	E2=[Necc2,Disp2]
	estraiTransf(E1,E2,Ct,Cu,Z).			%separa i dati e prova a fare trasferimenti
	
%separa i dati in liste diverse	
estraiTransf([Necc1,Disp1],[Necc2,Disp2],Ct,Cu,Z):- transfer(Necc1,Disp1,Necc2,Disp2,Ct,Cu,Z).

%traferimenti tra i due ospedali	
transfer(Necc1,_,Necc2,_,_,_,Res):-	Necc1==[0,0,0,0,0,0,0,0], Necc2==[0,0,0,0,0,0,0,0], 
									Res=['Disponibilita sopperibile con scambi interni',[],0].
transfer(Necc1,Disp1,Necc2,Disp2,Ct,Cu,Res):-	(Necc1\=[0,0,0,0,0,0,0,0]; Necc2\=[0,0,0,0,0,0,0,0]), 
								sposta(Disp1,Necc2,Ct,Cu,R), sposta(Disp2,Necc1,Ct,Cu,S), sum(R,S,Res).	

%condensa i risultati in un'unica stringa
sum(['impossibile',_],_,['Impossibile eseguire lo scambio di sacche tra ospedali',[],'Inf']).
sum(_,['impossibile',_],['Impossibile eseguire lo scambio di sacche tra ospedali',[],'Inf']).
sum([K1,K2],[Y1,Y2],[K1,Y1,C]):- (K1\='impossibile', Y1\='impossibile'), C is K2+Y2.
	
%controlla se 2 liste sono uguali (ritorna 0) o diverse(1)	
check([],[],0).
check([X|Xs],[Y|Ys],K):- X==Y, check(Xs,Ys,K).	
check([X|_],[Y|_],K):- X\=Y, K is 1.
						
%somma i numeri in una lista	
count([],L,Ct,Cu,R):- L\=0-> R is L*Cu+Ct; R is 0.
count([N|Ys],L,Ct,Cu,R):- M is L+N,
					count(Ys,M,Ct,Cu,R).						

%scambio sangue interno								
%faccio le combinazioni scorrendo [N|Ys] e ogni volta k trovo n>0 provo a fare uno scambio
interChange(Disp,[],_,Necc,[X,Disp]):- reverse(Necc,X).
interChange(Disp,[N|Ys],P,Necc,Z):-	
										N==0, 	
										Q is P+1,
										interChange(Disp,Ys,Q,[N|Necc],Z).

interChange(Disp,[N|Ys],P,Necc,Z):-	
										N>0, 		
										switch(P,Disp,NDisp),		%NDisp e' il nuovo Disp con o senza scambi
										check(Disp,NDisp,K),		%K mi dice se ho fatto uno scambio (1)										
										NN is N-K,					
										interbis(K,NDisp,N,NN,Ys,P,Necc,Z).								
	
interbis(K,Disp,N,NN,Ys,P,Necc,Z):-
			K==1,
			interChange(Disp,[NN|Ys],P,Necc,Z).
interbis(K,Disp,N,NN,Ys,P,Necc,Z):-
			K==0,
			Q is P+1,
			interChange(Disp,Ys,Q,[N|Necc],Z).
			
	
%scambio sangue esterno
outerChange(_,[],_,R,R).

outerChange(Disp,[N|Ys],P,R,Z) :-
	N==0, 
	Q is P+1, 
	outerChange(Disp,Ys,Q,R,Z).

%da rivedere
outerChange(Disp,[N|Ys],P,R,Z) :-
	N>0, 
	switch(P,Disp,NDisp),
	check(Disp,NDisp,K), %se lo scambio e' stato effettuato K=1
	NN is N-K,
	sub(Disp,NDisp,RDisp),
	add(R,RDisp,NR), %aggiorno R
	outerBis(K,NDisp,NN,Ys,P,NR,Z).
	
outerBis(K,Disp,NN,Ys,P,R,Z):-
	(K==1-> outerChange(Disp,[NN|Ys],P,R,Z); outerChange(Disp,[],P+1,'impossibile',Z)).				
					
%operazioni su liste
add([],[],[]).
add([X|Xs],[Y|Ys],[Z|Zs]):-
	Z is X+Y,
	add(Xs,Ys,Zs).
	
sub([],[],[]).
sub([X|Xs],[Y|Ys],[Z|Zs]):-
	Z is X-Y,
	sub(Xs,Ys,Zs).
	
%calcolo costo sommando sacche
sposta(Disp,Necc,Ct,Cu,[X,C]):- 
	outerChange(Disp,Necc,0,[0,0,0,0,0,0,0,0],X), %genera il sangue da trasferire considerando le necessita'
	count1(X,0,Ct,Cu,C).

count1(X,P,Ct,Cu,C):-
	(X=='impossibile'-> C = 0; count(X,P,Ct,Cu,C)).

%trovare il valore minimo in una lista					
list_min([L|Ls], Min) :-
    list_min(Ls, L, Min).

list_min([], Min, Min).
list_min([L|Ls], Min0, Min) :-
    min2(L,Min0,Min1),
    list_min(Ls, Min1, Min).
 
min2([Xs,Xss,X],[Ys,Yss,Y],Z):-
	min1(X,Y,X)-> Z=[Xs,Xss,X]; Z=[Ys,Yss,Y].

min1('Inf',Y,Y).
min1(X,'Inf',X).
min1(X,Y,_):- 
	(X\='Inf', Y\='Inf',X == min(X,Y)) -> min1(X,Y,X).
	   				
%funzioni nd per le combinazioni del sangue
%c'e' sempre il caso ==0 in quanto mi serve anche sapere se lo scambio e' stato fatto o no

%A_ puo' ricevere da O_ e da A_
switch(0,[A_,B_,AB_,O_,A,B,AB,O],[X,B_,AB_,O_,A,B,AB,O]):- A_>0, X is A_-1.
switch(0,[A_,B_,AB_,O_,A,B,AB,O],[A_,B_,AB_,X,A,B,AB,O]):- O_>0, X is O_-1.	
switch(0,[0,B_,AB_,O_,A,B,AB,O],[0,B_,AB_,O_,A,B,AB,O]).
switch(0,[A_,B_,AB_,0,A,B,AB,O],[A_,B_,AB_,0,A,B,AB,O]).	

%B_ puo' ricevere da O_ e da B_
switch(1,[A_,B_,AB_,O_,A,B,AB,O],[A_,X,AB_,O_,A,B,AB,O]):- B_>0, X is B_-1.	
switch(1,[A_,B_,AB_,O_,A,B,AB,O],[A_,B_,AB_,X,A,B,AB,O]):- O_>0, X is O_-1.
switch(1,[A_,0,AB_,O_,A,B,AB,O],[A_,0,AB_,O_,A,B,AB,O]).	
switch(1,[A_,B_,AB_,0,A,B,AB,O],[A_,B_,AB_,0,A,B,AB,O]).

%AB_ puo' ricevere da tutti, purche' RH-
switch(2,[A_,B_,AB_,O_,A,B,AB,O],[A_,B_,X,O_,A,B,AB,O]) :- AB_>0, X is AB_-1.	
switch(2,[A_,B_,AB_,O_,A,B,AB,O],[X,B_,AB_,O_,A,B,AB,O]):- A_>0,  X is A_-1.	
switch(2,[A_,B_,AB_,O_,A,B,AB,O],[A_,X,AB_,O_,A,B,AB,O]):- B_>0,  X is B_-1.	
switch(2,[A_,B_,AB_,O_,A,B,AB,O],[A_,B_,AB_,X,A,B,AB,O]):- O_>0,  X is O_-1.	
switch(2,[A_,B_,0,O_,A,B,AB,O],[A_,B_,0,O_,A,B,AB,O]).
switch(2,[0,B_,AB_,O_,A,B,AB,O],[0,B_,AB_,O_,A,B,AB,O]).	
switch(2,[A_,0,AB_,O_,A,B,AB,O],[A_,0,AB_,O_,A,B,AB,O]).		
switch(2,[A_,B_,AB_,0,A,B,AB,O],[A_,B_,AB_,0,A,B,AB,O]).	

%O_ puo' ricevere solo da O_
switch(3,[A_,B_,AB_,O_,A,B,AB,O],[A_,B_,AB_,X,A,B,AB,O]):- O_>0, X is O_-1.	
switch(3,[A_,B_,AB_,0,A,B,AB,O],[A_,B_,AB_,0,A,B,AB,O]).	

%A+ puo' ricevere da O_, da A_, O+, A+
switch(4,X,Y):-switch(0,X,Y).
switch(4,[A_,B_,AB_,O_,A,B,AB,O],[A_,B_,AB_,O_,X,B,AB,O]):- A>0, X is A-1.
switch(4,[A_,B_,AB_,O_,A,B,AB,O],[A_,B_,AB_,O_,A,B,AB,X]):- O>0, X is O-1.	
switch(4,[A_,B_,AB_,O_,0,B,AB,O],[A_,B_,AB_,O_,0,B,AB,O]).
switch(4,[A_,B_,AB_,O_,A,B,AB,0],[A_,B_,AB_,O_,A,B,AB,0]).

%B puo' ricevere da O_, da B_, da O+ e da B+
switch(5,X,Y):-switch(1,X,Y).
switch(5,[A_,B_,AB_,O_,A,B,AB,O],[A_,B_,AB_,O_,A,X,AB,O]):- B>0, X is B-1.	
switch(5,[A_,B_,AB_,O_,A,B,AB,O],[A_,B_,AB_,O_,A,B,AB,X]):- O>0, X is O-1.
switch(5,[A_,B_,AB_,O_,A,0,AB,O],[A_,B_,AB_,O_,A,0,AB,O]).	
switch(5,[A_,B_,AB_,O_,A,B,AB,0],[A_,B_,AB_,O_,A,B,AB,0]).

%AB+ puo' ricevere da tutti
switch(6,X,Y):- switch(2,X,Y).
switch(6,[A_,B_,AB_,O_,A,B,AB,O],[A_,B_,AB_,O_,A,B,X,O]) :- AB>0, X is AB-1.	
switch(6,[A_,B_,AB_,O_,A,B,AB,O],[A_,B_,AB_,O_,X,B,AB,O]):- A>0,  X is A-1.	
switch(6,[A_,B_,AB_,O_,A,B,AB,O],[A_,B_,AB_,O_,A,X,AB,O]):- B>0,  X is B-1.	
switch(6,[A_,B_,AB_,O_,A,B,AB,O],[A_,B_,AB_,O_,A,B,AB,X]):- O>0,  X is O-1.	
switch(6,[A_,B_,AB_,O_,A,B,0,O],[A_,B_,AB_,O_,A,B,0,O]).
switch(6,[A_,B_,AB_,O_,0,B,AB,O],[A_,B_,AB_,O_,0,B,AB,O]).	
switch(6,[A_,B_,AB_,O_,A,0,AB,O],[A_,B_,AB_,O_,A,0,AB,O]).		
switch(6,[A_,B_,AB_,O_,A,B,AB,0],[A_,B_,AB_,O_,A,B,AB,0]).	

%O+ puo' ricevere solo da O_ e O+
switch(7,X,Y):-switch(3,X,Y).
switch(7,[A_,B_,AB_,O_,A,B,AB,O],[A_,B_,AB_,O_,A,B,AB,X]):- O>0, X is O-1.	
switch(7,[A_,B_,AB_,O_,A,B,AB,0],[A_,B_,AB_,O_,A,B,AB,0]).	
