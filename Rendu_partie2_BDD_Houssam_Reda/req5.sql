select qu.id_user usr,count(distinct lo.id_object),nvl(min(number_object),0) as minimum,nvl(max(number_object),0) as maximum,nvl(avg(number_object),0) as average,count(distinct lo2.id_object)  
from quotation qu 
left join (
        select l.id_user ,l.id_list,count(lo.id_object) number_object
        from (
                select * 
                from liste 
                where list_name 
                not like 'wish%'
        ) l
        join liste_objet lo 
        on lo.id_list=l.id_list
        group by l.id_user,l.id_list
) l
on qu.id_user=l.id_user
left join  liste_objet lo
on l.id_list=lo.id_list
left join (
        select l.id_user ,l.id_list
        from (
                select * 
                from liste 
                where list_name 
                like 'wish%'
        ) l
        join liste_objet lo 
        on lo.id_list=l.id_list
        group by l.id_user,l.id_list
) l1
on qu.id_user=l1.id_user
left join  liste_objet lo2
on l1.id_list=lo2.id_list
group by qu.id_user
having qu.id_user in (
        select   distinct qu1.id_user
        from quotation qu1
        join quotation qu2
        on qu1.id_user=qu2.id_user
        AND  extract (YEAR from qu1.note_date)<extract (YEAR from sysdate) 
        AND extract (YEAR from qu1.note_date)>extract (YEAR from sysdate)-2
        AND extract (YEAR FROM qu1.note_date)=extract (YEAR FROM qu2.note_date)
        AND extract (MONTH from qu1.note_date)=extract (MONTH FROM qu2.note_date)-1 
        join quotation qu3
        on qu1.id_user = qu3.id_user
        AND extract(YEAR from qu1.note_date)=extract (YEAR FROM qu3.note_date)
        AND extract (MONTH from qu1.note_date)=extract (MONTH FROM qu3.note_date)-2
);