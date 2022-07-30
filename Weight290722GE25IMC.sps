**********************************************************************************************************
*
* MANTENDO AS GESTANTES QUE ENGRAVIDARAM EM USO DE CART
*
***************************************************************************************************************

 *APAGUE janela de resultados.
OUTPUT CLOSE all.


GET FILE='E:/PesoMundoReal/R1/AposComeco17.sav'.
dataset name AposComeco.
dataset activate AposComeco.
compute imc_ini = (peso/ ( (altura/100)*(altura/100) )).

execute.

ECHO "Avaliadas para elegibilidade:".

DATASET ACTIVATE APOSCOMECO.
DESCRIPTIVES VARIABLES=record_id
  /STATISTICS=MEAN.


DATASET ACTIVATE APOSCOMECO.
DATASET COPY  DataNonempty.
DATASET ACTIVATE DataNonempty.
DATASET CLOSE APOSCOMECO.
FILTER OFF.
USE ALL.
SELECT IF (prontu > 0).
EXECUTE.

ECHO "Avaliadas para elegibilidade depois de excluir recordes em branco:".

DATASET ACTIVATE DataNonempty.
DESCRIPTIVES VARIABLES=prontu
  /STATISTICS=MEAN.

DATASET ACTIVATE DataNonempty.
DATASET COPY  TemPesoEntr.
DATASET ACTIVATE TemPesoEntr.
DATASET CLOSE DataNonempty.
FILTER OFF.
USE ALL.
SELECT IF ( peso NE 9999).
EXECUTE.

ECHO "Avaliadas para elegibilidade depois de excluir gestantes sem peso na entrada:".
DATASET ACTIVATE TemPesoEntr.
DESCRIPTIVES VARIABLES=prontu
  /STATISTICS=MEAN.

DATASET ACTIVATE TemPesoEntr.
DATASET COPY  TemPesoPar.
DATASET ACTIVATE TemPesoPar.
DATASET CLOSE TemPesoEntr.
FILTER OFF.
USE ALL.
SELECT IF ( pespar NE 9999).
EXECUTE.

ECHO "Avaliadas para elegibilidade depois de excluir gestantes sem peso na última visita antes do parto:".
DATASET ACTIVATE TemPesoPar.
DESCRIPTIVES VARIABLES=prontu
  /STATISTICS=MEAN.

*a pesquisa comecou em agosto de 2014 que eh quando a primeira paciente recebeu RALTEGRAVIR.
COMPUTE sdate = Date.DMY(1,1,2000).



DATASET ACTIVATE TemPesoPar.
DATASET COPY  TemInitarv.
DATASET ACTIVATE TemInitarv.
DATASET CLOSE TemPesoPar.
FILTER OFF.
USE ALL.
SELECT IF (dt_ini ge sdate).
EXECUTE.

ECHO "Avaliadas para elegibilidade depois de excluir gestantes sem data do início do TARV:".
DATASET ACTIVATE TemInitarv.
DESCRIPTIVES VARIABLES=prontu
  /STATISTICS=MEAN.


compute diasuso = datediff(dt_par,dt_ini,'days').
compute antpart = datediff(dt_pes, dt_ini, 'days').
compute weeksgest = ig_parto - datediff(dt_par,dt_pes,'weeks').
compute diaspes = datediff(predat, dt_pes, 'days').
Recode diaspes(0 thru 0=1).
execute.

DATASET ACTIVATE TemInitArv.
DATASET COPY  efz.
DATASET ACTIVATE efz.
FILTER OFF.
USE ALL.
*SELECT IF ( ((arvhfs___5 EQ 1) and (diaspes > 14) ) or ( (arvhfs___17 EQ 1) and (diaspes > 14 ) ) or  ( (arvhfs___2 EQ 1) and (diaspes > 14 ) ) ).
*SELECT IF ((diaspes > 14) and ((arvhfs___10 EQ 1)) or ((qlesqu___10 eq 1) and (antpart LT 180) and (antpart ge 0 ) )).
*SELECT IF ((arvhfs___10 EQ 1) and (diaspes > 14)).
*SELECT IF ( (engrav eq 1 ) and  ((qlesqu___21 eq 1) and (antpart LT 90) and (antpart ge 0 )) or ((qlesqu___8 eq 1) and (antpart LT 90) and (antpart ge 0 )) ).
SELECT IF ( (imc_ini ge 25 ) and  (engrav eq 1 ) and  ( (qlesqu___21 eq 1) or (qlesqu___8 eq 1) ) and  (antpart GE 180)  ).
*SELECT IF ( ( diaspes GT 14)  and ( (qlesqu___21 eq 1) or (qlesqu___8 eq 1) ) ).


EXECUTE.

ECHO "Eligíveis e engravidaram em uso:".
DATASET ACTIVATE efz.
DESCRIPTIVES VARIABLES=prontu
  /STATISTICS=MEAN.
*dataset close efz.

DATASET ACTIVATE TemInitArv.
DATASET COPY  integr.
DATASET ACTIVATE integr.
dataset close TemInitArv.
FILTER OFF.
USE ALL.
*SELECT IF ( (engrav eq 2) and (diaspes>14) and ( (arvhfs___21 eq 1) or (arvhfs___8 eq 1))  ).
*SELECT IF ( sysmis(engrav) and ( (arvhfs___21 eq 1) or (arvhfs___8 eq 1) ) and ( diaspes ge 14) ).
select if ( ( (arvhfs___21 eq 1) or (arvhfs___8 eq 1) ) and ( diaspes ge 30.5) and (imc_ini ge 25 )).
EXECUTE.

ECHO "Eligíveis e comeceram RAL ou DTG depois de engravidar:".
DATASET ACTIVATE integr.
DESCRIPTIVES VARIABLES=prontu
  /STATISTICS=MEAN.

DATASET ACTIVATE integr.
DATASET COPY  ralt.
DATASET ACTIVATE ralt.
FILTER OFF.
USE ALL.
SELECT IF ( ((qlesqu___21 eq 1) and (antpart LT 180) and (antpart ge 0 )) or (arvhfs___21 eq 1)  ).
EXECUTE.

ECHO "Eligíveis e tomaram RAL:".
DATASET ACTIVATE ralt.
DESCRIPTIVES VARIABLES=prontu
  /STATISTICS=MEAN.
dataset close ralt.

DATASET ACTIVATE integr.
DATASET COPY dolu.
DATASET ACTIVATE dolu.
*DATASET CLOSE integr.
FILTER OFF.
USE ALL.
SELECT IF ( ( (qlesqu___8 eq 1) and (antpart LT 180) and (antpart ge 0 ) ) or (arvhfs___8 eq 1)  ).
EXECUTE.

ECHO "Eligíveis e tomaram DTG:".
DATASET ACTIVATE dolu.
DESCRIPTIVES VARIABLES=prontu
  /STATISTICS=MEAN.
dataset close dolu.

dataset activate efz.
compute medicine =1.
execute.

dataset activate integr.
compute medicine=2.
execute.

add files file integr / file efz.
SAVE OUTFILE="C:/Users/Fuller/Documents/banco080522.sav".
Execute.
dataset name merged1.

dataset activate merged1.
compute wtchng = ( (pespar - peso) / (diaspes / 7 ) ).
compute wks = ( diaspes / 7 ).
compute rawwt = (pespar - peso).
execute.

VALUE LABELS
medicine
1 'Experiente'
2 'Virgem'.
EXECUTE.

compute categ = 0.

*Set categ to 1 if wtchng > 18 to 2 if >= 0.18 and <=0.59 and to 3 if >0.59.
if(wtchng < 0.18) categ= 1.
if((wtchng >= 0.18) and (wtchng <= 0.59)) categ= 2.
if(wtchng > 0.59) categ= 3.


*Optionally, add value labels.
add value labels categ 1 'Low weight gain' 2 'Normal weight gain' 3 'High weight gain'.


*Variavel categorica para ganho ou perda de peso.
compute ganper =0.

if(wtchng>= 0) ganper = 1.

add value labels ganper 0 'Weight loss' 1 'Weight gain'.
EXECUTE.

compute macros =0.
if(pesnas > 4000)macros=1.
add value labels macros 0 'Normal weight' 1 'Macrosomia'.
execute.

* Chart Builder. 
* Chart Builder. 
GGRAPH 
  /GRAPHDATASET NAME="graphdataset" VARIABLES=categ COUNT()[name="COUNT"] medicine MISSING=LISTWISE REPORTMISSING=NO 
  /GRAPHSPEC SOURCE=INLINE. 
BEGIN GPL 
  SOURCE: s=userSource(id("graphdataset")) 
  DATA: categ=col(source(s), name("categ"), unit.category()) 
  DATA: COUNT=col(source(s), name("COUNT")) 
  DATA: medicine=col(source(s), name("medicine"), unit.category()) 
  COORD: rect(dim(1,2), cluster(3,0)) 
  GUIDE: axis(dim(1), label("categ")) 
  GUIDE: axis(dim(2), label("Percent"), delta(5)) 
  GUIDE: legend(aesthetic(aesthetic.color.interior), label("medicine")) 
  GUIDE: text.title( label( "Antepartum rate of weight change by cART regimen" ) )
  SCALE: cat(dim(1), include("1.00", "2.00", "3.00")) 
  SCALE: linear(dim(2), include(0)) 
  ELEMENT: interval(position(summary.percent(medicine*COUNT*categ)), color.interior(medicine), shape.interior(shape.square)) 
END GPL.

*compute imc_ini = (peso/ ( (altura/100)*(altura/100) )).
compute imc_fim = (pespar / ( (altura/100)*(altura/100) )).
compute lgcv1 = lg10(cv_1+1).
compute lgcv2 = lg10(cv_2+1).
EXECUTE.

variable labels imc_ini 'BMI (kg/m2) at study entry'.
variable labels lgcv1 'Log10 HIV RNA VL (copies/mL) at study entry'.
variable labels weeksgest 'Gestational age at study entry (weeks)'.
variable labels id_ent 'Age at baseline (yrs)'.
variable labels wks 'Weeks from entry to near delivery weight'.
execute.

recode cv_1 (0 thru 199=1) (200 thru 999=2) (1000 thru 9999=3) (10000 thru 100000000=4) INTO cvcat.
variable labels cvcat 'Baseline HIV RNA VL cp/mL'.
execute.

value labels
cvcat
1 '<200'
2 '200-999'
3 '1000-9999'
4 '>=10,000'.
execute.

recode ini_cd (0 thru 199=1) (200 thru 499=2) (500 thru 2000=3) into cdcat.
variable labels cdcat 'Baseline CD4 cells/mm3'.
execute.

value labels
cdcat
1 '<200'
2 '200-499'
3 '>= 500'.
execute.

recode raca (6=3).
execute.

compute imcchng = (imc_fim - imc_ini)/wks.
execute.

examine wtchng imcchng by medicine
/statistics descriptives.
execute.

NPAR TESTS
/K-W=wtchng BY medicine(1 2)
/MISSING ANALYSIS.
execute.

*oneway wtchng by medicine
/missing analysis.
*execute.

NPAR TESTS
/K-W=imcchng BY medicine(1 2)
/MISSING ANALYSIS.
execute.

*oneway imcchng by medicine
/missing analysis.
*execute.

******************************************************************************************************************************
*
* TABLE 1
*
*****************************************************************************************************************************.
dataset activate merged1.

compute prem37= 0.

*Set prem37 to 1 if ig_parto < 37 to 0 if ig_parto >= 37.
if(ig_parto < 37) prem37 = 1.
if(Missing(ig_part)) prem37 = 99.

*Add value labels.
add value labels prem37 0 '>= 37 sem ao nascer' 1 '< 37 sem ao nascer'.

compute prem35= 0.

*Set prem35 to 1 if ig_parto < 35 to 0 if ig_parto >= 35.
if(ig_parto < 35) prem35 = 1.
if(Missing(ig_part)) prem35 = 99.

*Add value labels.
add value labels prem35 0 '>= 35 sem ao nascer' 1 '< 35 sem ao nascer'.

compute lbw= 0.

*Set lbw to 1 if pesnas < 2500 to 0 if pesnas >= 2500.
if(pesnas < 2500) lbw = 1.

*Add value labels.
add value labels lbw 0 'Peso ao nascer >= 2500 g' 1 'Peso ao nascer < 2500 g'.

compute elbw= 0.

*Set elbw to 1 if pesnas < 1500 to 0 if pesnas >= 1500.
if(pesnas < 1500) elbw = 1.

*Add value labels.
add value labels elbw 0 'Peso ao nascer >= 1500 g' 1 'Peso ao nascer < 1500 g'.

add value labels pig 0 'Normal for gestational age' 1 'Small for gestational age'.

compute compo = 0.
if( (lbw =1) or (prem37=1) or (PIG=1)) compo =1.
execute.


NPAR TESTS
/K-W=imc_ini BY medicine(1 2)
/MISSING ANALYSIS.

examine imc_ini by medicine
/statistics descriptives.
execute.

NPAR TESTS
/K-W=imc_fim BY medicine(1 2)
/MISSING ANALYSIS.

NPAR TESTS
/K-W=id_ent BY medicine(1 2)
/MISSING ANALYSIS.

examine id_ent by medicine
/statistics descriptives.
execute.

NPAR TESTS
/K-W=lgcv1 BY medicine(1 2)
/MISSING ANALYSIS.

examine lgcv1 by medicine
/statistics descriptives.
execute.

NPAR TESTS
/K-W=lgcv2 BY medicine(1 2)
/MISSING ANALYSIS.

examine lgcv2 by medicine
/statistics descriptives.
execute.


NPAR TESTS
/K-W=ini_cd BY medicine(1 2)
/MISSING ANALYSIS.

examine ini_cd by medicine
/statistics descriptives.
execute.


NPAR TESTS
/K-W=wks BY medicine(1 2)
/MISSING ANALYSIS.

examine wks by medicine
/statistics descriptives.
execute.

NPAR TESTS
/K-W=weeksgest BY medicine(1 2)
/MISSING ANALYSIS.

examine weeksgest by medicine
/statistics descriptives.
execute.

NPAR TESTS
/K-W=peso BY medicine(1 2)
/MISSING ANALYSIS.

examine peso by medicine
/statistics descriptives.
execute.

NPAR TeSTS
/K-W=antpart by medicine(1 2)
/MISSING ANALYSIS.

recode antpart (-99999 thru 0=0).
execute.


examine antpart by medicine
/statistics descriptives.
execute.

NPAR Tests
/K-W=diasuso by medicine(1 2)
/Missing analysis.
execute.

examine diasuso by medicine
/statistics descriptives.
execute.

examine pespar by medicine
/statistics descriptives.
execute.


NPAR TESTS
/K-W=pespar BY medicine(1 2)
/MISSING ANALYSIS.
execute.

crosstabs raca cvcat cdcat categ ganper prem37 prem35 lbw elbw pig compo estadociv escola tabagismo etilismo glicose desfec macros by medicine 
  /FORMAT=AVALUE TABLES 
  /statistics=chisq
  /CELLS=COUNT column
  /COUNT ROUND CELL
/MISSING=TABLE.
execute.

* Chart Builder. 
GGRAPH 
  /GRAPHDATASET NAME="graphdataset" VARIABLES=medicine wtchng MISSING=LISTWISE REPORTMISSING=NO 
  /GRAPHSPEC SOURCE=INLINE. 
BEGIN GPL 
  SOURCE: s=userSource(id("graphdataset")) 
  DATA: medicine=col(source(s), name("medicine"), unit.category()) 
  DATA: wtchng=col(source(s), name("wtchng")) 
  DATA: id=col(source(s), name("$CASENUM"), unit.category()) 
  COORD: rect(dim(1,2), transpose()) 
  GUIDE: axis(dim(1), label("cART regimen")) 
  GUIDE: axis(dim(2), label("Rate of weight change kg/wk")) 
  GUIDE: text.title( label( "Rates of change for weight by cART regimen" ) )
  SCALE: cat(dim(1), include("1.00", "2.00")) 
  SCALE: linear(dim(2), include(0), min(-0.5), max(1) )
  ELEMENT: schema(position(bin.quantile.letter(medicine*wtchng)), label(id), color(medicine)) 
END GPL.

* Chart Builder. 
GGRAPH 
  /GRAPHDATASET NAME="graphdataset" VARIABLES=medicine imcchng MISSING=LISTWISE REPORTMISSING=NO 
  /GRAPHSPEC SOURCE=INLINE. 
BEGIN GPL 
  SOURCE: s=userSource(id("graphdataset")) 
  DATA: medicine=col(source(s), name("medicine"), unit.category()) 
  DATA: imcchng=col(source(s), name("imcchng")) 
  DATA: id=col(source(s), name("$CASENUM"), unit.category()) 
  COORD: rect(dim(1,2), transpose()) 
  GUIDE: axis(dim(1), label("cART regimen")) 
  GUIDE: axis(dim(2), label("Rate of BMI change kg/m2/wk")) 
  GUIDE: text.title( label( "Rates of BMI change by cART regimen" ) )
  SCALE: cat(dim(1), include("1.00", "2.00")) 
  SCALE: linear(dim(2), include(0), min(-0.5), max(1) )
  ELEMENT: schema(position(bin.quantile.letter(medicine*imcchng)), label(id), color(medicine)) 
END GPL.



GGRAPH 
  /GRAPHDATASET NAME="graphdataset" VARIABLES=wks rawwt medicine MISSING=LISTWISE REPORTMISSING=NO 
  /GRAPHSPEC SOURCE=INLINE. 
BEGIN GPL 
  SOURCE: s=userSource(id("graphdataset")) 
  DATA: wks=col(source(s), name("wks")) 
  DATA: rawwt=col(source(s), name("rawwt")) 
  DATA: medicine=col(source(s), name("medicine"), unit.category()) 
  GUIDE: axis(dim(1), label("Weeks in use of cART")) 
  GUIDE: axis(dim(2), label("Weight change (kg) since entry")) 
  GUIDE: legend(aesthetic(aesthetic.color.exterior), label("cART regimen")) 
  GUIDE: text.title( label( "Antepartum weight change by cART regimen" ) )
  SCALE: cat(aesthetic(aesthetic.color.exterior), include("1.00", "2.00")) 
  ELEMENT: point(position(wks*rawwt), color.exterior(medicine)) 
  SCALE: cat(aesthetic(aesthetic.color.interior), map(("EFZ", color.skyblue), ("INSTI", color.green))) 
  ELEMENT: line(position(smooth.linear(wks * rawwt)), shape(medicine))
 END GPL.

dataset activate merged1.
dataset copy merged2.
dataset activate merged2.
*dataset close merged1.
FILTER OFF.
USE ALL.
*select if(medicine eq 2).
execute.


dataset activate efz.
dataset close efz.

dataset activate integr.
*dataset close integr.

