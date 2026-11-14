-- Sommières : plan urbain reconstitué à partir des rues, places et façades réelles.
-- Vidourle nord-sud ; pont romain est-ouest ; vieille ville dense au pied du château.
-- Chaque édifice patrimonial possède son propre constructeur et sa parcelle dédiée.
return function(C)
    local S = C.sommieres
    local M = C.materials
    local function put(x,y,z,n) C.put(x,y,z,n) end
    local function fill(x1,y1,z1,x2,y2,z2,n) C.fill(x1,y1,z1,x2,y2,z2,n) end
    local function clear(x1,y1,z1,x2,y2,z2) C.clear(x1,y1,z1,x2,y2,z2) end
    local function lamp(x,y,z) C.lamp(x,y,z) end

    -- Maisons du centre ancien : volumes mitoyens serrés, trois niveaux fréquents,
    -- rez-de-chaussée commerçant, volets colorés, balcons en fer et tuiles canal.
    local function townhouse(x,z,w,d,levels,front,variant,wall,roof,balcony,frame)
        local x2,z2=x+w-1,z+d-1
        local mid=math.floor((x+x2)/2)
        local faceZ=(front=="north") and z or ((front=="south") and z2 or nil)
        local faceX=(front=="west") and x or ((front=="east") and x2 or nil)
        fill(x,0,z,x2,0,z2,M.paving)
        fill(x,1,z,x2,levels*5,z2,wall or S.plaster)
        clear(x+1,1,z+1,x2-1,levels*5-1,z2-1)

        -- Soubassement en pierre de taille et bandeaux d'étage.
        for _,px in ipairs({x,x+1,x2-1,x2}) do
            fill(px,1,z,px,3,z,M.limestone)
            fill(px,1,z2,px,3,z2,M.limestone)
        end
        for floor=1,levels do
            local fy=floor*5
            fill(x,fy,z,x2,fy,z,M.ashlar)
            fill(x,fy,z2,x2,fy,z2,M.ashlar)
        end

        -- Colombages sur certaines maisons, sinon enduit à la chaux ou pierre claire.
        if frame then
            for _,px in ipairs({x,x+3,mid,x2-3,x2}) do
                fill(px,1,z,px,levels*5,z,M.timber)
                fill(px,1,z2,px,levels*5,z2,M.timber)
            end
            fill(x,levels*5,z,x2,levels*5,z,M.timber)
            fill(x,levels*5,z2,x2,levels*5,z2,M.timber)
        end

        -- Vitrines et portes du rez-de-chaussée.
        if faceZ then
            clear(mid-1,1,faceZ,mid+1,3,faceZ)
            put(mid,1,faceZ,S.door)
            put(x+3,2,faceZ,(variant%2==0) and S.shutter_blue or S.shutter_green)
            put(x2-3,2,faceZ,(variant%3==0) and S.shutter_green or S.shutter_blue)
        elseif faceX then
            clear(faceX,1,mid-1,faceX,3,mid+1)
            put(faceX,1,mid,S.door)
            put(faceX,2,z+4,S.shutter_blue)
            put(faceX,2,z2-4,S.shutter_green)
        end

        for f=1,levels do
            local wy=2+f*5
            if faceZ then
                for _,px in ipairs({x+3,mid,x2-3}) do
                    if math.abs(px-mid)>1 or f>1 then
                        put(px,wy,faceZ,(variant%2==0) and S.shutter_green or S.shutter_blue)
                    end
                end
            elseif faceX then
                put(faceX,wy,z+4,S.shutter_green)
                put(faceX,wy,z2-4,S.shutter_blue)
            end
        end

        -- Encorbellement d'un étage sur deux, typique des façades anciennes.
        if variant%3==1 and levels>=2 then
            if faceZ then
                local bz=(front=="north") and z-1 or z2+1
                fill(x+1,6,bz,x2-1,6,bz,M.timber)
            end
        end

        -- Balcon ou garde-corps en ferronnerie sur les façades de place.
        if balcony and faceZ then
            local bz=(front=="north") and z-1 or z2+1
            put(mid,7,bz,S.balcony)
            put(mid-1,7,bz,S.balcony)
            put(mid+1,7,bz,S.balcony)
        end

        -- Toiture à deux pans en tuiles canal, avec faîtage et cheminée.
        local roofY=levels*5+1
        local half=math.max(3,math.floor(w/2))
        for k=0,half-1 do
            local y=roofY+k
            fill(x+k,y,z-1,x+k,y,z2+1,roof or S.roof)
            fill(x2-k,y,z-1,x2-k,y,z2+1,roof or S.roof)
        end
        fill(mid,roofY+half,z-1,mid,roofY+half,z2+1,S.limestone)
        fill(x+2,roofY+1,z+2,x+3,roofY+4,z+3,M.ashlar)
        lamp(x2-2,4,z2-2)
    end

    -- Immeuble à arcades : caves et ateliers inondables au niveau bas, logements au-dessus.
    local function arcaded_house(x,z,w,d,levels,front,roof,variant)
        local x2,z2=x+w-1,z+d-1
        local mid=math.floor((x+x2)/2)
        fill(x,0,z,x2,0,z2,M.paving)
        -- Arcades ouvertes : piliers, impostes et arcs en pierre.
        for _,px in ipairs({x,x+math.floor(w/3),x+math.floor(2*w/3),x2}) do
            fill(px,1,z,px,5,z,S.limestone)
            fill(px,1,z2,px,5,z2,S.limestone)
        end
        fill(x,5,z,x2,5,z,S.ashlar)
        fill(x,5,z2,x2,5,z2,S.ashlar)
        -- Arcs segmentaires en blocs taillés, ouvertures réellement franchissables.
        for _,baseZ in ipairs({z,z2}) do
            for _,cx in ipairs({x+math.floor(w/6),x+math.floor(w/2),x+math.floor(5*w/6)}) do
                for dx=-3,3 do
                    local arch=math.floor(math.sqrt(math.max(0,9-dx*dx))*0.9)
                    put(cx+dx,3+arch,baseZ,S.arcade)
                end
            end
        end
        fill(x,6,z,x2,levels*5+5,z2, S.plaster)
        clear(x+1,7,z+1,x2-1,levels*5+4,z2-1)
        for floor=1,levels do
            local fy=6+floor*5
            for _,px in ipairs({x+3,mid,x2-3}) do
                put(px,fy,z2,(variant%2==0) and S.shutter_green or S.shutter_blue)
                put(px,fy,z,(variant%2==0) and S.shutter_blue or S.shutter_green)
            end
            fill(x,fy,z,x2,fy,z,S.limestone)
        end
        local roofY=levels*5+7
        local half=math.floor(w/2)
        for k=0,half-1 do
            fill(x+k,roofY+k,z-1,x+k,roofY+k,z2+1,roof or S.roof)
            fill(x2-k,roofY+k,z-1,x2-k,roofY+k,z2+1,roof or S.roof)
        end
        fill(mid,roofY+half,z-1,mid,roofY+half,z2+1,S.limestone)
    end

    local function small_gate(x,z,width,height,front)
        -- Porte urbaine à arc plein cintre, claveaux alternés et passage traversant.
        local x2=x+width-1
        local mid=math.floor((x+x2)/2)
        local z2=z+5
        fill(x,1,z,x+2,height,z2,S.ashlar)
        fill(x2-2,1,z,x2,height,z2,S.ashlar)
        clear(mid-3,1,z,mid+3,height-4,z2)
        for dx=-4,4 do
            local arch=math.floor(math.sqrt(math.max(0,16-dx*dx))*0.75)
            put(mid+dx,height-4+arch,z,S.arcade)
            put(mid+dx,height-4+arch,z2,S.arcade)
        end
        fill(x,height,z,x2,height,z2,S.ashlar)
        fill(x-2,height+1,z-1,x2+2,height+1,z2+1,S.roof)
    end

    -- Éléments du Vidourle et des quais.
    local function build_vidourle()
        -- Lit minéral, eau au niveau bas et berges en pente douce.
        fill(-40,-8,680,40,-5,1015,S.bridge)
        fill(-39,-4,680,39,-1,1015,C.water_node)
        for z=680,1015 do
            fill(-44,-2,z,-41,1,z,S.ashlar)
            fill(41,-2,z,44,1,z,S.ashlar)
            fill(-48,-3,z,-45,-1,z,"gdo_core:sable")
            fill(45,-3,z,48,-1,z,"gdo_core:sable")
        end
        -- Escaliers de descente au fleuve au nord et au sud du vieux centre.
        for step=0,5 do
            fill(43-step,-step,740+step*2,48,-step,746+step*2,S.pebbles)
            fill(-48,-step,918+step*2,-43+step,-step,924+step*2,S.pebbles)
        end
        -- Quais pavés, murs de soutènement et bornes en pierre.
        fill(45,0,710,51,0,1000,S.paving)
        fill(-52,0,710,-46,0,1000,S.paving)
        fill(44,1,710,44,4,1000,S.ashlar)
        fill(-45,1,710,-45,4,1000,S.ashlar)
        for z=720,990,18 do
            put(48,1,z,M.stone)
            put(-49,1,z,M.stone)
        end
    end

    -- 21 arches réparties sur 189 m. Les sept arches au-dessus du chenal restent
    -- ouvertes et visibles ; les quatorze autres passent sous les immeubles du pont.
    local function build_roman_bridge()
        for _,cx in ipairs({-90,-81,-72,-63,-54,-45,-36,-27,-18,-9,0,9,18,27,36,45,54,63,72,81,90}) do
            -- Anneau de l'arche extrudé sur toute la largeur du tablier.
            for dx=-5,5 do
                local curve=math.floor(1+math.sqrt(math.max(0,25-dx*dx))*0.8)
                for z=840,860 do
                    put(cx+dx,curve,z,S.bridge)
                    put(cx+dx,curve-1,z,S.limestone)
                end
            end
        end
        -- Tablier continu, légèrement surélevé et chaussée pavée.
        fill(-98,5,839,98,7,861,S.ashlar)
        fill(-98,8,840,98,8,860,S.paving)
        fill(-98,9,839,98,9,840,S.limestone)
        fill(-98,9,860,98,9,861,S.limestone)

        -- Rampes d'accès : le tablier ne se termine pas par une chute au niveau des rues.
        for step=0,8 do
            local westX=-122+step*3
            local eastX=98+step*3
            fill(westX,step,842,westX+2,step,858,S.paving)
            fill(eastX,8-step,842,eastX+2,8-step,858,S.paving)
        end
        fill(122,0,854,135,0,859,S.paving)

        -- Parapets bas, lanternes et bornes.
        for x=-94,94,8 do
            put(x,9,839,S.bridge)
            put(x,9,861,S.bridge)
        end
        for _,x in ipairs({-90,-63,-36,36,63,90}) do
            lamp(x,10,839)
            lamp(x,10,861)
        end
    end

    -- Maisons au-dessus des arches absorbées par le tissu urbain du pont.
    local function build_bridge_houses()
        townhouse(-93,817,22,20,2,"south",1,S.plaster,S.roof,true,true)
        townhouse(-69,817,24,20,2,"south",2,S.rose,S.terracotta,true,false)
        arcaded_house(-93,864,23,19,2,"north",S.terracotta,3)
        arcaded_house(-67,864,23,19,2,"north",S.roof,4)
        townhouse(106,817,22,19,2,"south",5,S.ochre,S.roof,true,false)
        arcaded_house(106,864,21,19,2,"north",S.terracotta,6)
        townhouse(44,817,23,20,2,"south",7,S.plaster,S.terracotta,true,true)
        townhouse(69,864,23,19,2,"north",8,S.rose,S.roof,true,false)
    end

    -- Faubourg du Pont, rive droite : maisons sur rue, ateliers et remises.
    local function build_faubourg_house_01()
        townhouse(-151,790,22,25,2,"east",11,S.ochre,S.terracotta,false,false)
    end
    local function build_faubourg_house_02()
        townhouse(-151,874,25,22,3,"east",12,S.plaster,S.roof,true,false)
    end
    local function build_faubourg_house_03()
        arcaded_house(-126,790,22,26,2,"east",S.terracotta,13)
    end
    local function build_faubourg_house_04()
        townhouse(-124,875,22,22,2,"east",14,S.rose,S.roof,false,true)
    end
    local function build_faubourg_workshop()
        arcaded_house(-149,830,24,30,1,"east",S.roof,15)
        C.put(-126,2,844,S.door)
        C.put(-129,2,844,S.shutter_blue)
    end

    -- Grand-Rue / rue Antonin-Paris : maisons mitoyennes irrégulières.
    local function build_grand_rue_01()
        townhouse(58,722,22,24,3,"south",21,S.ochre,S.terracotta,true,false)
    end
    local function build_grand_rue_02()
        townhouse(82,721,18,25,2,"south",22,S.plaster,S.roof,true,true)
    end
    local function build_grand_rue_03()
        townhouse(103,720,24,22,3,"south",23,S.rose,S.terracotta,true,false)
    end
    local function build_grand_rue_04()
        townhouse(130,722,14,25,2,"south",24,S.ochre,S.roof,false,true)
    end
    local function build_grand_rue_05()
        townhouse(58,754,21,24,2,"north",25,S.plaster,S.terracotta,true,false)
    end
    local function build_grand_rue_06()
        townhouse(81,754,19,24,3,"north",26,S.rose,S.roof,true,true)
    end
    local function build_grand_rue_07()
        townhouse(102,754,20,25,2,"north",27,S.ochre,S.terracotta,false,false)
    end
    local function build_grand_rue_08()
        townhouse(125,754,18,24,3,"north",28,S.plaster,S.roof,true,false)
    end

    -- Place des Docteurs-Dax / place du Marché : trois côtés d'arcades et halle.
    local function build_market_arcades()
        arcaded_house(49,815,34,20,2,"south",S.terracotta,31)
        arcaded_house(49,884,34,20,2,"north",S.roof,32)
        arcaded_house(49,835,18,49,2,"east",S.terracotta,33)
        arcaded_house(84,835,14,49,2,"west",S.roof,34)
        -- Place ouverte, dallage clair et espace de marché.
        fill(67,0,838,84,0,881,S.paving)
        -- Halle démontable, étals en bois et couvertures en tuiles.
        for _,x in ipairs({70,79}) do
            fill(x,1,847,x,5,847,M.wood)
            fill(x,1,870,x,5,870,M.wood)
        end
        fill(70,5,847,79,5,870,S.terracotta)
        fill(70,6,858,79,6,858,S.limestone)
        put(73,1,851,M.table)
        put(77,1,851,M.barrel)
        lamp(75,7,857)
    end

    -- Maison consulaire de la rue Marx-Dormoy, sur le pont habité.
    local function build_consular_house()
        townhouse(142,870,16,22,3,"south",35,S.ashlar,S.terracotta,true,false)
        fill(146,2,891,152,4,891,S.limestone)
        put(149,3,891,M.gold) -- relief rappelant l'ancienne justice royale
        put(148,2,891,M.gold)
        put(150,2,891,M.gold)
    end

    -- Place Jean-Jaurès : maisons de commerce, façades hautes et terrasses.
    local function build_jean_jaures_house_01()
        townhouse(109,790,22,20,3,"east",41,S.ochre,S.terracotta,true,false)
        -- Placette dégagée entre les maisons de commerce et la Grand-Rue.
        fill(133,0,790,153,0,810,S.paving)
    end
    local function build_jean_jaures_house_02()
        arcaded_house(156,790,18,20,2,"west",S.roof,42)
    end

    -- Place Saussine : maison restaurée à façade ocre et mascaron sculpté.
    local function build_saussine_house()
        townhouse(58,925,23,23,3,"south",51,S.rose,S.roof,true,true)
        put(69,7,948,M.gold)
        put(68,7,948,M.gold)
        put(70,7,948,M.gold)
    end

    -- Hôtel particulier et immeuble de la place de la République.
    local function build_republic_manor()
        townhouse(103,925,25,20,3,"west",61,S.ashlar,S.terracotta,true,false)
        arcaded_house(132,925,22,20,2,"west",S.roof,62)
        fill(75,0,927,101,0,951,S.paving)
    end

    -- Porte du Bourguet et montée du château.
    local function build_bourguet_gate()
        -- La Porte du Bourguet marque l'entrée de la rue Antonin-Paris.
        small_gate(139,747,18,16,"west")
        fill(145,0,753,151,0,833,S.paving)
        -- Accès distinct vers le château depuis la place de la République.
        fill(145,0,941,151,0,954,S.paving)
        for step=0,8 do
            fill(149-step,step,962+step*5,153-step,step,965+step*5,S.ashlar)
        end
    end

    -- Tour de l'Horloge / beffroi-porte dans l'alignement de la Grand-Rue.
    local function build_clock_tower()
        -- Porte du Beffroi : entrée médiévale dans l'axe du pont romain.
        fill(123,0,836,139,0,852,S.paving)
        fill(125,1,838,137,28,850,S.ashlar)
        clear(127,1,840,135,26,848)
        clear(129,1,838,133,8,838)
        -- Cadrans côté pont et côté vieille ville.
        fill(128,18,837,134,24,837,S.limestone)
        fill(128,18,851,134,24,851,S.limestone)
        put(131,21,836,M.gold)
        put(131,21,852,M.gold)
        fill(124,29,837,138,30,851,S.terracotta)
        small_gate(124,837,14,16,"south")
        lamp(131,24,837)
    end

    -- Église Saint-Pons : nef, contreforts, clocher carré, toit en tuiles canal.
    local function build_saint_pons()
        fill(55,0,952,100,0,996,S.paving)
        fill(61,1,954,94,17,992,S.limestone)
        clear(63,1,956,92,15,990)
        for _,x in ipairs({61,70,84,94}) do
            fill(x,1,954,x+1,16,954,S.ashlar)
            fill(x,1,992,x+1,16,992,S.ashlar)
        end
        for layer=0,9 do
            fill(61+layer,18+layer,953,61+layer,18+layer,993,S.terracotta)
            fill(94-layer,18+layer,953,94-layer,18+layer,993,S.terracotta)
        end
        -- Clocher carré latéral.
        fill(77,1,956,96,33,975,S.ashlar)
        clear(79,1,958,94,29,973)
        for _,z in ipairs({960,966,972}) do
            put(77,23,z,S.shutter_blue)
            put(96,23,z,S.shutter_green)
        end
        fill(75,34,954,98,36,977,S.terracotta)
        fill(83,37,962,90,50,970,S.ashlar)
        fill(81,50,960,92,53,972,S.roof)
        put(86,54,966,M.gold)
    end

    -- Château sur l'éperon rocheux : tour Brémond carrée et fragments de remparts.
    local function build_castle_spur()
        -- Relief rocheux en gradins, escarpé au-dessus des toits.
        fill(103,0,970,169,3,1010,S.pebbles)
        fill(111,4,974,168,8,1008,S.ashlar)
        fill(118,9,978,166,13,1004,S.ashlar)
        fill(124,14,983,164,18,1000,S.ashlar)
        -- Enceinte haute et tour carrée principale.
        fill(124,19,985,164,28,998,S.limestone)
        clear(126,20,987,162,27,996)
        fill(111,19,985,124,24,987,S.ashlar)
        fill(164,19,985,172,24,987,S.ashlar)
        fill(124,29,985,164,29,998,S.roof)
        fill(135,20,985,153,47,1002,S.ashlar)
        clear(137,21,987,151,45,1000)
        for _,x in ipairs({136,153}) do
            fill(x,22,987,x,43,987,S.limestone)
        end
        fill(133,48,983,155,50,1004,S.roof)
        put(144,51,993,M.gold)
        -- Muraille suivant le rebord de l'éperon.
        fill(103,14,984,124,19,989,S.ashlar)
        fill(164,15,982,174,21,987,S.ashlar)
        for _,x in ipairs({108,120,168}) do
            fill(x,20,983,x+4,28,989,S.limestone)
            fill(x-1,29,982,x+5,29,990,S.roof)
        end
    end

    -- Quais Frédéric-Gaussorgues et Cléon-Griolet : platanes alignés, bancs et murets.
    local function build_quays_and_plane_trees()
        for _,z in ipairs({700,790,910}) do
            C.fill(46,0,z,50,0,z+4,S.paving)
            C.fill(-51,0,z,-47,0,z+4,S.paving)
            -- Tronc élevé et large houppier, aligné sur les quais.
            C.fill(48,1,z+2,48,12,z+2,M.wood)
            C.fill(39,10,z-5,57,13,z+9,M.leaves)
            C.fill(42,14,z-2,54,16,z+6,M.leaves)
            C.fill(-49,1,z+2,-49,12,z+2,M.wood)
            C.fill(-58,10,z-5,-40,13,z+9,M.leaves)
            C.fill(-55,14,z-2,-46,16,z+6,M.leaves)
            put(47,1,z+5,M.bench)
            put(-50,1,z+5,M.bench)
        end
    end

    -- Petites places et réseau de rues basses en damier pour l'écoulement des crues.
    local function build_street_grid()
        -- Axes est-ouest.
        for _,z in ipairs({710,750,790,830,900,920,970}) do
            fill(50,0,z,165,0,z+4,S.paving)
        end
        -- Axes nord-sud.
        for _,x in ipairs({52,92,132,160}) do
            fill(x,0,705,x+4,0,970,S.paving)
        end
        -- Rues basses et petites dessertes du quartier ancien.
        fill(74,0,808,78,0,923,S.paving)
        fill(110,0,810,114,0,925,S.paving)
        fill(52,0,891,162,0,895,S.paving)
        fill(52,0,965,162,0,969,S.paving)
    end

    local function build_signs_and_lights()
        -- Lanternes murales, enseignes et repères de quartier.
        for _,p in ipairs({{61,809},{95,809},{129,809},{61,919},{95,919},{129,919},
            {60,749},{95,749},{130,749},{60,899},{95,899},{130,899}}) do
            lamp(p[1],4,p[2])
        end
        put(87,1,883,M.banner)
        put(111,1,812,M.banner)
        put(153,1,892,M.banner)
        -- Pierre de passage sur la place du Marché : retour au Château des Brumes.
        put(77,1,858,"gdo_city:waystone")
    end

    return function()
        build_vidourle()
        build_street_grid()
        build_roman_bridge()
        build_bridge_houses()
        build_faubourg_house_01()
        build_faubourg_house_02()
        build_faubourg_house_03()
        build_faubourg_house_04()
        build_faubourg_workshop()
        build_grand_rue_01()
        build_grand_rue_02()
        build_grand_rue_03()
        build_grand_rue_04()
        build_grand_rue_05()
        build_grand_rue_06()
        build_grand_rue_07()
        build_grand_rue_08()
        build_market_arcades()
        build_consular_house()
        build_jean_jaures_house_01()
        build_jean_jaures_house_02()
        build_saussine_house()
        build_republic_manor()
        build_bourguet_gate()
        build_clock_tower()
        build_saint_pons()
        build_castle_spur()
        build_quays_and_plane_trees()
        build_signs_and_lights()
    end
end
