-- This script was authored poorly by Jake

-- 1) draw circles on ground where we want people to pick up / deliver trailers to
-- 2) populate circles with contracts that reset after x minutes
-- 3) when contract selected spawn trailer and mark map with delivery location
-- 4) detach trailer in delivery zone get paid and despawn the trailer

--stop people from being a cunt and taking every job smile

ESX=nil

Citizen.CreateThread(function()
	while ESX == nil do
		TriggerEvent('esx:getSharedObject', function(obj) ESX = obj end)
		Citizen.Wait(0)
    end
end)

-- Citizen.CreateThread(function()
--     while true do
--         Citizen.Wait(1000)
--         print(GetEntityCoords(PlayerPedId()))
--     end
-- end)

local zones = {
    docks1 = vector3(-126.441,-2416.368,5.635);
    docks2 = vector3(72.188, -2723.332, 5.640);
    docks3 = vector3(767.764, -2976.236, 5.436);
    elysian = vector3(1732.646, -1572.726, 112.251);
    mine = vector3(2691.211, 2749.734, 36.684);
    hdepot = vector3(2668.795, 3526.945, 51.554);
    hlabs = vector3(3473.114, 3678.832, 33.029);
    chicken = vector3(11.735, 6276.994, 31.052);
    salvage = vector3(-189.377, 6290.231, 31.471);
}

local trailers ={
    elysian = vector3(1716.545, -1569.526, 112.620)
}

local hasAlreadyEnteredMarker, isInMarker, where

local jobs = {}
function openContractMenu(start)
    ESX.UI.Menu.CloseAll()
    local elements = {}
    for k,v in pairs(jobs) do
        if v[1] == start then
            table.insert(elements,{label='Dest: '..v[2]..' Type: '..v[3]..' Pay: '..v[4]..'',start=v[1],dest=v[2],type=v[3],pay=v[4], value='take_job'})
        end
    end
    ESX.UI.Menu.Open('default',GetCurrentResourceName(),'contracts',{
        title = 'Trucking',
        align = 'center',
        elements = elements
    }, function(data,menu)
        local action = data.current.value
        if action == 'take_job' then
            spawnTrailer(data.current.start,data.current.dest,data.current.type)
            for k,v in pairs(elements) do
                if data.current.label == elements[k].label then
                    print("Attempting to remove from elements at :"..k)
                    table.remove(elements,k)
                    break
                end
            end

            for k,v in pairs(jobs) do
                if v[2]==data.current.dest and v[3]==data.current.type and v[4]==data.current.pay then
                    print("Attempting to remove from jobs at :"..k)
                    table.remove(jobs,k)
                end
            end
        end
        menu.close()
    end)

end

function tablelength(T)
    local count = 0
    for _ in pairs(T) do 
        count = count + 1 
    end
    return count
end

function spawnTrailer(start,dest,type)
    local hash
    if type=="Liquid" then
        hash=GetHashKey("tanker")
    else
        local random= math.random(7)
        if random == 1 then
            hash=GetHashKey("trailerlogs")
        elseif random == 2 then
            hash=GetHashKey("docktrailer")
        elseif random == 3 then
            hash=GetHashKey("trailers")
        elseif random == 4 then
            hash=GetHashKey("tr4")
        elseif random == 5 then
            hash=GetHashKey("trailerlarge")
        elseif random == 6 then
            hash=GetHashKey("trailers4")
        else
            hash=GetHashKey("freighttrailer")
        end
    end
    
    RequestModel(hash)
    while not HasModelLoaded(hash) do
        RequestModel(hash)
        print("Attempting to spawn trailer")
        Citizen.Wait(0)
    end

    print(start)
    trailer = CreateVehicle(trailerhash, trailers[start].x, trailers[start].y, trailers[start].z, 0.0, true, false)
    SetEntityAsMissionEntity(trailer, true, true)
    AttachVehicleToTrailer(truck, trailer, 1.1)

    --set delivery
    delivery=AddBlipForCoord(zones[dest].x,zones[dest].y,zones[dest].z)
    SetBlipSprite(deliveryblip, 304)
    SetBlipDisplay(deliveryblip, 4)
    SetBlipScale(deliveryblip, 1.0)
    SetBlipColour(deliveryblip, 5)
    SetBlipAsShortRange(deliveryblip, true)
    BeginTextCommandSetBlipName("STRING")
    AddTextComponentString("Delivery point")
    EndTextCommandSetBlipName(deliveryblip)
  
  SetBlipRoute(deliveryblip, true) --Add the route to the blip
end

local zoneLength = tablelength(zones)

function createNewJob(start)
    local random = math.random(zoneLength)
    local dest
    local i=1
    for k,v in pairs(zones) do
        if i<=random then
            dest=k
            i=i+1
        else
            break
        end
    end
    local rand2 = math.random(2)
    local type
    if rand2 == 1 then
        type="Freight"
    else
        type="Liquid"
    end
    local pay = math.ceil(Vdist(zones[dest],zones[start])*0.05)
    if type == "Liquid" then
        pay = math.ceil(pay*1.2)
    end
    table.insert(jobs,{start, dest, type, pay})
end

Citizen.CreateThread(function()
    while true do
        while tablelength(jobs)<50 do
            random=math.random(zoneLength)
            local start
            local i=1
            for k,v in pairs(zones) do
                if i<=random then
                    start=k
                    i=i+1
                else
                    break
                end
            end
            createNewJob(start)
        end
        Citizen.Wait(600000)
    end
end)

Citizen.CreateThread(function()
    while true do
        Citizen.Wait(0)
        local playerCoords = GetEntityCoords(PlayerPedId())
        isInMarker=false
        local distance
        for k,v in pairs(zones) do
            distance = Vdist(playerCoords.x,playerCoords.y,playerCoords.z, v.x,v.y,v.z)
            --print(distance)
            if distance < 500 then
                DrawMarker(39, v.x,v.y,v.z, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 1.0, 1.0, 1.0, 0, 255, 0, 100, false, true, 2, true, false, false, false)
                if distance < 5 then
                    isInMarker = true
                    ESX.ShowNotification("Press E to Interact")
                    where = k
                end
            end
        end
    end
end)

--Controls
Citizen.CreateThread(function()
    while true do
        Citizen.Wait(0)
        local vehicle = GetVehiclePedIsIn(GetPlayerPed(-1),false)
        local name = (GetDisplayNameFromVehicleModel(GetEntityModel(vehicle)))
        if isInMarker and IsControlJustPressed(0,38) then
            if name =='PHANTOM' or 'PACKER' or 'PHANTOM3' or 'HAULER' then
                print("Big truck 4Head")
                openContractMenu(where)
            else
                ESX.ShowNotification("Come back with a Semi")
            end
        end

    end
end)

function dump(o)
    if type(o) == 'table' then
       local s = '{ '
       for k,v in pairs(o) do
          if type(k) ~= 'number' then k = '"'..k..'"' end
          s = s .. '['..k..'] = ' .. dump(v) .. ','
       end
       return s .. '} '
    else
       return tostring(o)
    end
 end