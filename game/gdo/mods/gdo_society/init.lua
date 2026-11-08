-- GDO — Guildes fondatrices, guildes de joueurs et villages persistants.
-- Les données sont locales au monde Luanti ; migration backend prévue ultérieurement.
gdo_society = gdo_society or {}
local storage = minetest.get_mod_storage()
local founders = {
    bras_casses={name="Les Bras Cassés",x=-240,z=-240},
    mages_dimanche={name="Les Mages du Dimanche",x=240,z=-240},
    rats_bibliotheque={name="Les Rats de Bibliothèque",x=-240,z=240},
    seigneurs_navet={name="Les Seigneurs du Navet",x=240,z=240},
}
local PLOT = 11
local CREATE_LEVEL = 10
local guilds = minetest.deserialize(storage:get_string("guilds")) or {}
local counters = minetest.deserialize(storage:get_string("plot_counters")) or {}
local plots = minetest.deserialize(storage:get_string("player_plots")) or {}
local invites = minetest.deserialize(storage:get_string("invites")) or {}
local built = minetest.deserialize(storage:get_string("built_villages")) or {}

local function save()
    storage:set_string("guilds",minetest.serialize(guilds))
    storage:set_string("plot_counters",minetest.serialize(counters))
    storage:set_string("player_plots",minetest.serialize(plots))
    storage:set_string("invites",minetest.serialize(invites))
    storage:set_string("built_villages",minetest.serialize(built))
end
local function count(g)
    local n=0; for _ in pairs(g.members or {}) do n=n+1 end; return n
end
local function member(g,n) return g and g.members and g.members[n] == true end
local function role(g,n)
    if not g or not member(g,n) then return "visitor" end
    if g.leader == n then return "leader" end
    return (g.roles and g.roles[n]) or "member"
end
local function find_guild(name)
    local p=minetest.get_player_by_name(name)
    local id=p and p:get_meta():get_string("gdo_guild") or ""
    if id ~= "" and guilds[id] then return id,guilds[id] end
    for gid,g in pairs(guilds) do if member(g,name) then return gid,g end end
end
local function box(x1,y1,z1,x2,y2,z2,node)
    for x=x1,x2 do for y=y1,y2 do for z=z1,z2 do
        minetest.set_node({x=x,y=y,z=z},{name=node})
    end end end
end
local function clear(x1,y1,z1,x2,y2,z2)
    box(x1,y1,z1,x2,y2,z2,"air")
end

local textures={
    soil="unknown_node.png^[colorize:#8b7651:220",
    wood="unknown_node.png^[colorize:#79502f:220",
    stone="unknown_node.png^[colorize:#777777:220",
    roof="unknown_node.png^[colorize:#594653:220",
}
for id,desc in pairs({soil="Sol du village",wood="Bois de construction",stone="Pierre du village",roof="Toit de maison",marker="Borne de parcelle"}) do
    minetest.register_node("gdo_society:"..id,{
        description=desc,tiles={textures[id] or "unknown_node.png^[colorize:#d6b24c:220"},
        groups={cracky=2,oddly_breakable_by_hand=2},
    })
end

local function build_commons(g)
    local x,z=g.x,g.z
    box(x-12,0,z-12,x+12,0,z+12,"gdo_society:stone")
    local buildings={{-8,-8},{3,-8},{-8,3},{3,3}}
    for _,p in ipairs(buildings) do
        local bx,bz=x+p[1],z+p[2]
        box(bx,1,bz,bx+5,4,bz+5,"gdo_society:wood")
        clear(bx+2,2,bz,bx+3,3,bz)
        box(bx-1,5,bz-1,bx+6,5,bz+6,"gdo_society:roof")
    end
end
local function build_house(p)
    local x,z=p.x,p.z
    box(x,0,z,x+PLOT-1,0,z+PLOT-1,"gdo_society:soil")
    box(x+2,1,z+2,x+8,1,z+8,"gdo_society:wood")
    box(x+2,2,z+2,x+8,4,z+2,"gdo_society:wood")
    box(x+2,2,z+8,x+8,4,z+8,"gdo_society:wood")
    box(x+2,2,z+3,x+2,4,z+7,"gdo_society:wood")
    box(x+8,2,z+3,x+8,4,z+7,"gdo_society:wood")
    clear(x+4,2,z+2,x+6,3,z+2)
    box(x+1,5,z+1,x+9,5,z+9,"gdo_society:roof")
    box(x+3,6,z+3,x+7,6,z+7,"gdo_society:roof")
    minetest.set_node({x=x+5,y=1,z=z+5},{name="gdo_society:marker"})
end
local function allocate(name,gid)
    if plots[name] and plots[name].guild == gid then return plots[name] end
    local g=guilds[gid]; if not g then return nil end
    counters[gid]=(counters[gid] or 0)+1
    local n=counters[gid]-1
    local p={guild=gid,x=g.x-38+(n%5)*15,z=g.z+17+math.floor(n/5)*15,owner=name}
    plots[name]=p; g.plots=(g.plots or 0)+1
    build_house(p); save(); return p
end
local function assign(player,gid)
    local name=player:get_player_name(); local g=guilds[gid]
    if not g then return false end
    g.members=g.members or {}; g.roles=g.roles or {}
    g.members[name]=true
    if not g.leader or g.leader=="" then g.leader=name end
    player:get_meta():set_string("gdo_guild",gid)
    player:get_meta():set_string("gdo_guild_name",g.name)
    local p=allocate(name,gid)
    if p then
        minetest.after(0.5,function()
            local online=minetest.get_player_by_name(name)
            if online then
                online:set_pos({x=p.x+5,y=2,z=p.z+5})
                minetest.chat_send_player(name,"Bienvenue chez "..g.name.." ! Ta parcelle et ta petite maison standardisée t'attendent. /gdo_plot pour les coordonnées.")
            end
        end)
    end
    save(); return true
end
gdo_society.join_founder_guild=function(player,gid)
    if not founders[gid] or player:get_meta():get_string("gdo_guild") ~= "" then return false end
    return assign(player,gid)
end

local function inside(pos,x1,z1,x2,z2)
    return pos.x>=x1 and pos.x<=x2 and pos.z>=z1 and pos.z<=z2 and pos.y>=-5 and pos.y<=80
end
local function village_at(pos)
    for id,g in pairs(guilds) do
        if inside(pos,g.x-48,g.z-48,g.x+48,g.z+120) then return id,g end
    end
end
local function in_plot(pos,p)
    return p and inside(pos,p.x,p.z,p.x+PLOT-1,p.z+PLOT-1)
end
local function can_edit_common(g,name)
    local r=role(g,name); return r=="leader" or r=="officer" or r=="builder"
end
local previous=minetest.is_protected
minetest.is_protected=function(pos,name)
    if name and name~="" and minetest.check_player_privs(name,{protection_bypass=true}) then
        return previous and previous(pos,name) or false
    end
    if previous and previous(pos,name) then return true end
    local id,g=village_at(pos)
    if g then
        if not member(g,name or "") then return true end
        -- Une parcelle personnelle reste privée, même pour les officiers et bâtisseurs.
        for owner,p in pairs(plots) do
            if p.guild==id and in_plot(pos,p) then return owner~=name end
        end
        return not can_edit_common(g,name)
    end
    for owner,p in pairs(plots) do
        if owner~=name and in_plot(pos,p) then return true end
    end
    return false
end
minetest.register_on_protection_violation(function(pos,name)
    local _,g=village_at(pos)
    if g then
        minetest.chat_send_player(name,"Village de guilde : accès réservé aux membres autorisés. Ta parcelle personnelle reste modifiable par toi seul.")
        return
    end
    for owner,p in pairs(plots) do
        if owner~=name and in_plot(pos,p) then minetest.chat_send_player(name,"Cette parcelle appartient à "..owner.."."); return end
    end
end)

local function update_growth(g)
    if g.founder then return end
    local n=count(g)
    local stage=n>=20 and 4 or n>=10 and 3 or n>=5 and 2 or 1
    if stage<=(g.village_stage or 1) then return end
    g.village_stage=stage
    minetest.chat_send_all("Le village de "..g.name.." s'étoffe ! Niveau "..stage..", avec "..n.." membres.")
    local x,z=g.x,g.z
    if stage>=2 then box(x-24,1,z-24,x+24,3,z-23,"gdo_society:stone") end
    if stage>=3 then box(x-24,1,z+23,x+24,3,z+24,"gdo_society:stone") end
    if stage>=4 then
        box(x-24,1,z-24,x-23,5,z+24,"gdo_society:stone")
        box(x+23,1,z-24,x+24,5,z+24,"gdo_society:stone")
    end
    save()
end

minetest.register_chatcommand("gdo_plot",{
    description="Affiche les coordonnées de ta parcelle personnelle",
    func=function(name)
        local p=plots[name]
        if not p then return true,"Aucune parcelle attribuée. Choisis une maison au château." end
        return true,"Parcelle de "..p.owner.." dans "..(guilds[p.guild] and guilds[p.guild].name or p.guild)..": X "..p.x.." à "..(p.x+PLOT-1)..", Z "..p.z.." à "..(p.z+PLOT-1).."."
    end,
})
minetest.register_chatcommand("gdo_guild",{
    description="Affiche ta guilde et son village",
    func=function(name)
        local _,g=find_guild(name); if not g then return true,"Tu n'appartiens à aucune guilde." end
        return true,g.name.." — "..count(g).." membre(s), village niveau "..(g.village_stage or 1).."."
    end,
})
minetest.register_chatcommand("gdo_guild_leave",{
    description="Quitte ta guilde actuelle",
    func=function(name)
        local id,g=find_guild(name); if not g then return false,"Tu n'as pas de guilde." end
        if g.leader==name then
            local successor=nil
            for candidate in pairs(g.members or {}) do
                if candidate~=name then successor=candidate; break end
            end
            g.leader=successor or ""
            if successor then g.roles[successor]="leader" end
        end
        g.members[name]=nil; if g.roles then g.roles[name]=nil end
        plots[name]=nil
        local p=minetest.get_player_by_name(name)
        if p then p:get_meta():set_string("gdo_guild",""); p:get_meta():set_string("gdo_guild_name","") end
        save(); return true,"Tu as quitté "..g.name..". Ta maison reste dans le village, mais tu n'en as plus les droits."
    end,
})
minetest.register_chatcommand("gdo_guild_create",{
    params="<nom>",description="Fonde une guilde et son village (niveau 10 requis)",
    func=function(name,param)
        local title=(param or ""):match("^%s*(.-)%s*$")
        if not title or #title<3 or #title>32 then return false,"Le nom doit contenir 3 à 32 caractères." end
        local p=minetest.get_player_by_name(name); if not p then return false,"Joueur introuvable." end
        if math.max(1,p:get_meta():get_int("gdo_level"))<10 then return false,"Niveau 10 requis. Progression : /gdo_progression." end
        if find_guild(name) then return false,"Quitte d'abord ta guilde avec /gdo_guild_leave." end
        for _,g in pairs(guilds) do if g.name:lower()==title:lower() then return false,"Ce nom est déjà utilisé." end end
        local id="player_"..name:lower():gsub("[^%w_]","_")
        if guilds[id] then return false,"Tu as déjà fondé une guilde." end
        local idx=0; for _,g in pairs(guilds) do if not g.founder then idx=idx+1 end end
        local x,z=500+(idx%8)*120,500+math.floor(idx/8)*120
        local g={id=id,name=title,founder=false,x=x,z=z,leader=name,members={[name]=true},roles={[name]="leader"},plots=0,level=1,village_stage=1}
        guilds[id]=g
        -- Le joueur conserve son identité, mais reçoit une nouvelle parcelle dans le village qu'il fonde.
        p:get_meta():set_string("gdo_guild",id); p:get_meta():set_string("gdo_guild_name",title)
        build_commons(g); allocate(name,id); save()
        p:set_pos({x=x,y=2,z=z+20})
        minetest.chat_send_all(name.." fonde la guilde « "..title.." » ! Un nouveau village vient de naître.")
        return true,"Guilde créée. Invite des membres avec /gdo_guild_invite <joueur>."
    end,
})
minetest.register_chatcommand("gdo_guild_invite",{
    params="<joueur>",description="Invite un joueur dans ta guilde",
    func=function(name,target)
        local _,g=find_guild(name); if not g or not can_edit_common(g,name) then return false,"Droits insuffisants." end
        if not minetest.get_player_by_name(target) then return false,"Le joueur doit être connecté." end
        invites[target]=g.id; save()
        minetest.chat_send_player(target,name.." t'invite chez "..g.name..". Utilise /gdo_guild_join.")
        return true,"Invitation envoyée."
    end,
})
minetest.register_chatcommand("gdo_guild_join",{
    description="Accepte une invitation de guilde",
    func=function(name)
        local id=invites[name]; if not id or not guilds[id] then return false,"Aucune invitation valide." end
        if find_guild(name) then return false,"Quitte d'abord ta guilde actuelle." end
        local p=minetest.get_player_by_name(name); if not p then return false,"Joueur introuvable." end
        invites[name]=nil; assign(p,id); update_growth(guilds[id]); save()
        return true,"Tu as rejoint "..guilds[id].name.."."
    end,
})
minetest.register_chatcommand("gdo_guild_role",{
    params="<joueur> <member|builder|officer>",description="Attribue un rôle de guilde",
    func=function(name,param)
        local _,g=find_guild(name); if not g or g.leader~=name then return false,"Seul le chef peut attribuer les rôles." end
        local target,r=(param or ""):match("^(%S+)%s+(%S+)$")
        if not target or not member(g,target) then return false,"Ce joueur n'est pas membre." end
        if r~="member" and r~="builder" and r~="officer" then return false,"Rôle invalide." end
        g.roles[target]=r; save(); return true,"Rôle de "..target.." : "..r.."."
    end,
})

gdo_society.add_experience=function(player,amount)
    if not player or not player:is_player() or type(amount)~="number" or amount<=0 then return end
    local m=player:get_meta(); local xp=m:get_int("gdo_xp")+math.floor(amount)
    local level=math.max(1,m:get_int("gdo_level"))
    while xp>=level*100 do xp=xp-level*100; level=level+1; minetest.chat_send_player(player:get_player_name(),"Niveau supérieur : niveau "..level.." !") end
    m:set_int("gdo_xp",xp); m:set_int("gdo_level",level)
end
minetest.register_chatcommand("gdo_progression",{
    description="Affiche ton niveau et ton expérience",
    func=function(name)
        local p=minetest.get_player_by_name(name); if not p then return false,"Joueur introuvable." end
        local m=p:get_meta(); local l=math.max(1,m:get_int("gdo_level"))
        return true,"Niveau "..l.." — "..m:get_int("gdo_xp").."/"..(l*100).." XP. Fondation de guilde au niveau 10."
    end,
})

minetest.register_on_joinplayer(function(player)
    local id=player:get_meta():get_string("gdo_guild")
    if id~="" and guilds[id] then
        guilds[id].members=guilds[id].members or {}; guilds[id].members[player:get_player_name()]=true
        if not plots[player:get_player_name()] then allocate(player:get_player_name(),id) end
        update_growth(guilds[id])
    end
end)
minetest.register_on_mods_loaded(function()
    for id,d in pairs(founders) do
        if not guilds[id] then guilds[id]={id=id,name=d.name,founder=true,x=d.x,z=d.z,leader="",members={},roles={},plots=0,village_stage=1} end
        if not built[id] then build_commons(guilds[id]); built[id]=true end
    end
    save()
    minetest.log("action","[GDO] Les quatre guildes fondatrices et le système de villages sont prêts.")
end)
