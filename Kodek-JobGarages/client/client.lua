local QBCore = exports['qb-core']:GetCoreObject()

local PolicePeds = {}
local PlayerRentedVehicle = {}
local LocationBlips = {}
local PlayerJob = {}

local function OpenOxMenu(menuData, menuId)
    local oxOptions = {}
    for _, item in ipairs(menuData) do
        local option = {
            title = item.header or "",
            description = item.txt or "",
            icon = item.icon or "",
            disabled = item.isMenuHeader or false,
            onSelect = nil,
        }
        if item.params and item.params.event then
            option.onSelect = function()
                if item.params.isServer then
                    TriggerServerEvent(item.params.event, item.params.args)
                else
                    TriggerEvent(item.params.event, item.params.args)
                end
            end
        end
        table.insert(oxOptions, option)
    end

    lib.registerContext({
        id = menuId,
        title = menuData[1].header or "Menu",
        options = oxOptions,
    })
    lib.showContext(menuId)
end


local function OxInputDialog(title, inputs)
    return lib.inputDialog(title, inputs)
end

RegisterNetEvent('QBCore:Client:OnPlayerLoaded', function()
    PlayerJob = QBCore.Functions.GetPlayerData().job
    Blips()
end)

RegisterNetEvent('QBCore:Client:OnPlayerUnload', function()
    PlayerJob = {}
end)

RegisterNetEvent('QBCore:Client:OnJobUpdate', function(JobInfo)
    PlayerJob = JobInfo
    Blips()
end)

AddEventHandler('onResourceStart', function(resourceName)
    if GetCurrentResourceName() == resourceName then
        PlayerJob = QBCore.Functions.GetPlayerData().job
        Blips()
    end
end)

local function DrawText3D(x, y, z, text)
    SetTextScale(0.35, 0.35)
    SetTextFont(4)
    SetTextProportional(1)
    SetTextColour(255, 255, 255, 215)
    SetTextEntry("STRING")
    SetTextCentre(true)
    AddTextComponentString(text)
    SetDrawOrigin(x, y, z, 0)
    DrawText(0.0, 0.0)
    local factor = string.len(text) / 370
    DrawRect(0.0, 0.0 + 0.0125, 0.017 + factor, 0.03, 0, 0, 0, 75)
    ClearDrawOrigin()
end

local function ShowHelpNotification(text)
    SetTextComponentFormat("STRING")
    AddTextComponentString(text)
    DisplayHelpTextFromStringLabel(0, 0, 1, -1)
end

function FormatString(str)
    local code = ""
    local words = {}
    for word in string.gmatch(str, "%S+") do
        table.insert(words, word)
    end
    if #words > 1 then
        for i = 1, #words do
            local word = words[i]
            if string.len(word) >= 4 then
                code = code .. string.sub(word, 1, 2)
            else
                code = code .. string.upper(word)
            end
        end
    else
        local word = words[1]
        if string.len(word) >= 4 then
            code = string.sub(word, 1, 2)
        else
            code = string.upper(word)
        end
    end
    return code
end

function StartLoop(veh, vehname, time, player, station)
    local Notified = false
    local normalTime = time * 60000
    local reducedTime = math.floor(normalTime * 0.8)
    repeat
        if station ~= PlayerRentedVehicle[player].station then
            PlayerRentedVehicle[player] = nil
            break
        end
        if not DoesEntityExist(veh) then
            PlayerRentedVehicle[player] = nil
            QBCore.Functions.Notify(vehname .. " has been deleted", "error")           
            break
        end
        Wait(1000)
        normalTime = normalTime - 1000
        reducedTime = reducedTime - 1000
        if normalTime <= 0 then
            DeleteVehicle(veh)
            PlayerRentedVehicle[player] = nil
            DeleteEntity(veh)
            QBCore.Functions.Notify(Config.Locals['Notifications']['RentOver'] .. vehname .. " is over")
            break
        end
        if reducedTime <= 0 and not Notified then
            QBCore.Functions.Notify(Config.Locals['Notifications']['RentWarning'] .. vehname)
            Notified = true
        end
    until false or not PlayerRentedVehicle[player]
end

function Blips()
    for k, v in pairs(Config.Locations['Stations']) do
        local blip = LocationBlips[k]
        if Config.UseBlips then
            if HasJob(v.JobRequired) then
                if not blip then
                    if v.UseTarget then
                        blip = AddBlipForCoord(v.GeneralInformation['TargetInformation']['Coords'].x, v.GeneralInformation['TargetInformation']['Coords'].y, v.GeneralInformation['TargetInformation']['Coords'].z)
                    else
                        blip = AddBlipForCoord(v.GeneralInformation['MarkerInformation']['Coords'].x, v.GeneralInformation['MarkerInformation']['Coords'].y, v.GeneralInformation['MarkerInformation']['Coords'].z)
                    end
                    SetBlipDisplay(blip, 4)
                    SetBlipAsShortRange(blip, true)
                    LocationBlips[k] = blip
                end
                SetBlipSprite(blip, v.GeneralInformation['Blip']['BlipId'])
                SetBlipScale(blip, v.GeneralInformation['Blip']['BlipScale'])
                SetBlipColour(blip, v.GeneralInformation['Blip']['BlipColour'])
                BeginTextCommandSetBlipName("STRING")
                AddTextComponentString(v.GeneralInformation['Blip']['Title'])
                EndTextCommandSetBlipName(blip)
            elseif blip then
                RemoveBlip(blip)
                LocationBlips[k] = nil
            end
        end
    end
end

function HasJob(job)
    for k, v in pairs(Config.Locations['Stations']) do
        if type(job) == "table" then
            for _, j in ipairs(job) do
                if PlayerJob.name == j then
                    return true
                end
            end
        elseif job == "all" then
            return true
        elseif PlayerJob.name == job then
            return true
        end
        return false
    end
end

function GetNearbyPlayers(playerPed, distance)
    local playerList = {}
    local playerPed = playerPed or PlayerPedId()
    local myPos = GetEntityCoords(playerPed)
    local foundNearbyPlayers = false
    for _, player in ipairs(GetActivePlayers()) do
        local targetPed = GetPlayerPed(player)
        local targetPos = GetEntityCoords(targetPed)
        local distanceBetween = #(myPos - targetPos)
        if targetPed ~= playerPed then
            if distanceBetween <= distance then
                table.insert(playerList, {
                    id = GetPlayerServerId(player),
                    name = GetPlayerName(player)
                })
                foundNearbyPlayers = true
            end
        end
    end
    if not foundNearbyPlayers then
        return nil
    end
    return playerList
end

function SetTrunkItemsInfo(trunkitems)
    local items = {}
    for _, item in pairs(trunkitems) do
        local itemInfo = QBCore.Shared.Items[item.name:lower()]
        items[item.slot] = {
            name = itemInfo["name"],
            amount = tonumber(item.amount),
            info = item.info,
            label = itemInfo["label"],
            description = itemInfo["description"] or "",
            weight = itemInfo["weight"],
            type = itemInfo["type"],
            unique = itemInfo["unique"],
            useable = itemInfo["useable"],
            image = itemInfo["image"],
            slot = item.slot,
        }
    end
    return items
end

CreateThread(function()
    for k, v in pairs(Config.Locations['Stations']) do
        if not v.UsePurchasable and not v.UseRent then return end
        if v.UseTarget then
            local pedCoords = v.GeneralInformation['TargetInformation']['Coords']
            local pedModel = v.GeneralInformation['TargetInformation']['Ped']
            local pedExists = false
            for i, ped in ipairs(PolicePeds) do
                if DoesEntityExist(ped) and GetEntityModel(ped) == pedModel and GetEntityCoords(ped) == pedCoords then
                    pedExists = true
                    break
                end
            end
            if not pedExists then
                QBCore.Functions.LoadModel(pedModel)
                while not HasModelLoaded(pedModel) do
                    Wait(10)
                end
                local ped = CreatePed(0, pedModel, pedCoords.x, pedCoords.y, pedCoords.z, pedCoords.w, false, true)
                PlaceObjectOnGroundProperly(ped)
                FreezeEntityPosition(ped, true)
                SetEntityInvincible(ped, true)
                SetBlockingOfNonTemporaryEvents(ped, true)
                TaskStartScenarioInPlace(ped, v.GeneralInformation['TargetInformation']['Scenario'], 0, true)
                table.insert(PolicePeds, ped)
                exports[Config.Target]:AddTargetEntity(ped, {
                    options = {
                        {
                            event = "JobGarage:OpenMainMenu",
                            icon = Config.Locals['Targets']['GarageTarget']['Icon'],
                            label = Config.Locals['Targets']['GarageTarget']['Label'] .. k,
                            rjob = v.JobRequired,
                            userent = v.UseRent,
                            usepurchasable = v.UsePurchasable,
                            useownable = v.UseOwnable,
                            useliveries = v.UseLiveries,
                            useextras = v.UseExtras,
                            rentvehicles = v.VehiclesInformation['RentVehicles'],
                            purchasevehicles = v.VehiclesInformation['PurchaseVehicles'],
                            coordsinfo = v.VehiclesInformation['SpawnCoords'],
                            station = k,
                            canInteract = function()
                                return HasJob(v.JobRequired)
                            end,
                        },
                    },
                    distance = Config.Locals['Targets']['GarageTarget']['Distance'],
                })
            end
        else
            while true do
                local playerPos = GetEntityCoords(PlayerPedId())
                local distance = #(playerPos - v.GeneralInformation['MarkerInformation']['Coords'])
                if HasJob(v.JobRequired) then
                    if distance < 10 then
                        DrawMarker(v.GeneralInformation['MarkerInformation']['MarkerType'], v.GeneralInformation['MarkerInformation']['Coords'].x, v.GeneralInformation['MarkerInformation']['Coords'].y, v.GeneralInformation['MarkerInformation']['Coords'].z, 0.0, 0.0, 0.0, 0.0, 0.0, 0.7, 0.7, 0.5, 0.5, v.GeneralInformation['MarkerInformation']['MarkerColor'].R, v.GeneralInformation['MarkerInformation']['MarkerColor'].G, v.GeneralInformation['MarkerInformation']['MarkerColor'].B, v.GeneralInformation['MarkerInformation']['MarkerColor'].A, true, false, false, true, false, false, false)
                        if distance < 1.5 then
                            DrawText3D(v.GeneralInformation['MarkerInformation']['Coords'].x, v.GeneralInformation['MarkerInformation']['Coords'].y, v.GeneralInformation['MarkerInformation']['Coords'].z, "~g~E~w~ - " .. k .. " Police Garage")
                            if IsControlJustReleased(0, 38) then
                                local Data = {
                                    userent = v.UseRent,
                                    rentvehicles = v.VehiclesInformation['RentVehicles'],
                                    purchasevehicles = v.VehiclesInformation['PurchaseVehicles'],
                                    coordsinfo = v.VehiclesInformation['SpawnCoords'],
                                    station = k,
                                    rjob = v.JobRequired,
                                    useownable = v.UseOwnable,
                                    usepurchasable = v.UsePurchasable,
                                    useliveries = v.UseLiveries,
                                    useextras = v.UseExtras,
                                }
                                TriggerEvent("JobGarage:OpenMainMenu", Data)
                            end
                        end
                    end
                end
                Wait(0)
            end
        end
    end
end)

RegisterNetEvent('JobGarage:OpenMainMenu', function(data)
    local MainMenu = {
        {
            header = data.station .. " - Garage",
            icon = "fa-solid fa-circle-info",
            isMenuHeader = true,
        }
    }
    if data.userent then
        table.insert(MainMenu, {
            header = "Rent Vehicles",
            txt = "View and rent vehicles for a selected amount of time",
            icon = "fa-solid fa-file-contract",
            params = {
                event = "JobGarage:OpenRentingMenu",
                args = {
                    rentvehicles = data.rentvehicles,
                    coordsinfo = data.coordsinfo,
                    station = data.station,
                    job = data.rjob,
                    userent = data.userent,
                    purchasevehicles = data.purchasevehicles,
                    useownable = data.useownable,
                    useextras = data.useextras,
                    useliveries = data.useliveries,
                    usepurchasable = data.usepurchasable,
                },
            }
        })
    end
    if data.usepurchasable then
        table.insert(MainMenu, {
            header = "Purchase Vehicles",
            txt = "View and purchase vehicles to use as your own",
            icon = "fa-solid fa-money-check-dollar",
            params = {
                event = "JobGarage:OpenPurchaseMenu",
                args = {
                    purchasevehicles = data.purchasevehicles,
                    coordsinfo = data.coordsinfo,
                    station = data.station,
                    job = data.rjob,
                    useownable = data.useownable,
                    usepurchasable = data.usepurchasable,
                    useliveries = data.useliveries,
                    useextras = data.useextras,
                    userent = data.userent,
                    rentvehicles = data.rentvehicles,
                },
            }
        })
    end
    if IsPedInAnyVehicle(PlayerPedId(), false) and data.useliveries then
        table.insert(MainMenu, {
            header = "Choose Livery",
            txt = "Change your vehicle livery",
            icon = "fa-solid fa-spray-can",
            params = {
                event = "JobGarage:StartSelection",
                args = {
                    vehicle = GetVehiclePedIsIn(PlayerPedId(), false),
                    coordsinfo = data.coordsinfo,
                    type = "livery",
                },
            }
        })
    end
    if IsPedInAnyVehicle(PlayerPedId(), false) and data.useextras then
        table.insert(MainMenu, {
            header = "Choose Extras",
            txt = "Add or remove extras",
            icon = "fa-solid fa-plus-minus",
            params = {
                event = "JobGarage:OpenExtrasMenu",
                args = {
                    vehicle = GetVehiclePedIsIn(PlayerPedId(), false),
                    station = data.station,
                    userent = data.userent,
                    rentvehicles = data.rentvehicles,
                    purchasevehicles = data.purchasevehicles,
                    coordsinfo = data.coordsinfo,
                    job = data.rjob,
                    useownable = data.useownable,
                    useextras = data.useextras,
                    usepurchasable = data.usepurchasable,
                    useliveries = data.useliveries,
                },
            }
        })
    end
    if PlayerRentedVehicle[PlayerPedId()] and PlayerRentedVehicle[PlayerPedId()].station == data.station and data.userent and GetVehiclePedIsIn(PlayerPedId(), false) == PlayerRentedVehicle[PlayerPedId()].vehicle then
        table.insert(MainMenu, {
            header = "Return Vehicle",
            txt = "Return your rented vehicle",
            icon = "fa-solid fa-left-long",
            params = {
                event = "JobGarage:ReturnRentedVehicle",
            }
        })
    end
    table.insert(MainMenu, {
        header = "Close",
        icon = "fa-solid fa-xmark",
        params = {
            event = "ox_lib:closeMenu",
        },
    })
    OpenOxMenu(MainMenu, data.station .. "MainMenu")
end)

RegisterNetEvent("JobGarage:OpenExtrasMenu", function(data)
    local ExtrasMenu = {
        {
            header = data.station .. " - Extras Selection",
            icon = "fa-solid fa-circle-info",
            isMenuHeader = true,
        }
    }
    local hasExtras = false
    for i = 1, 13 do
        if DoesExtraExist(data.vehicle, i) then
            hasExtras = true
            if IsVehicleExtraTurnedOn(data.vehicle, i) then
                table.insert(ExtrasMenu, {
                    header = "Toggle Extra " .. i .. " Off",
                    icon = "fa-solid fa-xmark",
                    params = {
                        event = "JobGarage:VehicleExtra",
                        args = {
                            vehicle = data.vehicle,
                            extraid = i,
                            userent = data.userent,
                            rentvehicles = data.rentvehicles,
                            purchasevehicles = data.purchasevehicles,
                            coordsinfo = data.coordsinfo,
                            job = data.job,
                            station = data.station,
                            useownable = data.useownable,
                            useextras = data.useextras,
                            usepurchasable = data.usepurchasable,
                            useliveries = data.useliveries,
                        },
                    },
                })
            else
                table.insert(ExtrasMenu, {
                    header = "Toggle Extra " .. i .. " On",
                    icon = "fa-solid fa-circle-check",
                    params = {
                        event = "JobGarage:VehicleExtra",
                        args = {
                            vehicle = data.vehicle,
                            extraid = i,
                            userent = data.userent,
                            rentvehicles = data.rentvehicles,
                            purchasevehicles = data.purchasevehicles,
                            coordsinfo = data.coordsinfo,
                            job = data.job,
                            station = data.station,
                            useownable = data.useownable,
                            useextras = data.useextras,
                            usepurchasable = data.usepurchasable,
                            useliveries = data.useliveries,
                        },
                    },
                })
            end
        end
    end
    if not hasExtras then
        table.insert(ExtrasMenu, {
            header = "No Extras Available",
            icon = "fa-solid fa-exclamation-circle",
            isMenuHeader = true,
        })
    end
    table.insert(ExtrasMenu, {
        header = "Go Back",
        icon = "fa-solid fa-left-long",
        params = {
            event = "JobGarage:OpenMainMenu",
            args = {
                userent = data.userent,
                rentvehicles = data.rentvehicles,
                purchasevehicles = data.purchasevehicles,
                coordsinfo = data.coordsinfo,
                rjob = data.job,
                station = data.station,
                useownable = data.useownable,
                useextras = data.useextras,
                usepurchasable = data.usepurchasable,
                useliveries = data.useliveries,
            },
        },
    })
    OpenOxMenu(ExtrasMenu, data.station .. "ExtrasMenu")
end)

RegisterNetEvent("JobGarage:OpenRentingMenu", function(data)
    if QBCore.Functions.SpawnClear(vector3(data.coordsinfo['VehicleSpawn'].x, data.coordsinfo['VehicleSpawn'].y, data.coordsinfo['VehicleSpawn'].z), data.coordsinfo['CheckRadius']) then
        local RentingMenu = {
            {
                header = data.station .. " - Garage",
                icon = "fa-solid fa-circle-info",
                isMenuHeader = true,
            }
        }
        if not PlayerRentedVehicle[PlayerPedId()] then
            for k, v in pairs(data.rentvehicles) do
                table.insert(RentingMenu, {
                    header = "Rent " .. k,
                    txt = "Rent: " .. k .. "<br> For: " .. v.PricePerMinute .. "$ (Per Minute)",
                    icon = "fa-solid fa-car",
                    params = {
                        event = "JobGarage:ChooseRent",
                        args = {
                            price = v.PricePerMinute,
                            vehiclename = k,
                            vehicle = v.Vehicle,
                            coordsinfo = data.coordsinfo,
                            station = data.station,
                            job = data.job,
                        }
                    }
                })
            end
        elseif PlayerRentedVehicle[PlayerPedId()].station ~= data.station then
            for k, v in pairs(data.rentvehicles) do
                table.insert(RentingMenu, {
                    header = "Rent " .. k,
                    txt = "Rent: " .. k .. "<br> For: " .. v.PricePerMinute .. "$ (Per Minute)",
                    icon = "fa-solid fa-car",
                    params = {
                        event = "JobGarage:ChooseRent",
                        args = {
                            price = v.PricePerMinute,
                            vehiclename = k,
                            vehicle = v.Vehicle,
                            coordsinfo = data.coordsinfo,
                            station = data.station,
                            job = data.job,
                        }
                    }
                })
            end
        elseif GetVehiclePedIsIn(PlayerPedId(), false) ~= PlayerRentedVehicle[PlayerPedId()].vehicle or not IsPedInAnyVehicle(PlayerPedId(), false) then
            table.insert(RentingMenu, {
                header = "Return " .. PlayerRentedVehicle[PlayerPedId()].name .. " Before Renting",
                icon = "fa-solid fa-exclamation-circle",
                isMenuHeader = true,
            })
        end
        if PlayerRentedVehicle[PlayerPedId()] and PlayerRentedVehicle[PlayerPedId()].station == data.station and GetVehiclePedIsIn(PlayerPedId(), false) == PlayerRentedVehicle[PlayerPedId()].vehicle then
            table.insert(RentingMenu, {
                header = "Return Vehicle",
                txt = "Return your rented vehicle",
                icon = "fa-solid fa-left-long",
                params = {
                    event = "JobGarage:ReturnRentedVehicle",
                }
            })
        end
        table.insert(RentingMenu, {
            header = "Go Back",
            icon = "fa-solid fa-left-long",
            params = {
                event = "JobGarage:OpenMainMenu",
                args = {
                    userent = data.userent,
                    rentvehicles = data.rentvehicles,
                    purchasevehicles = data.purchasevehicles,
                    coordsinfo = data.coordsinfo,
                    rjob = data.job,
                    station = data.station,
                    useownable = data.useownable,
                    useextras = data.useextras,
                    usepurchasable = data.usepurchasable,
                    useliveries = data.useliveries,
                },
            },
        })
        OpenOxMenu(RentingMenu, data.station .. "RentingMenu")
    else
        QBCore.Functions.Notify(Config.Locals["Notifications"]["VehicleInSpawn"], "error")
    end
end)

RegisterNetEvent("JobGarage:OpenPurchaseMenu", function(data)
    local VehicleMenu = {
        {
            header = data.station .. " - Garage",
            icon = "fa-solid fa-circle-info",
            isMenuHeader = true,
        }
    }
    local sortedVehicles = {}
    for k, v in pairs(data.purchasevehicles) do
        if PlayerJob.grade.level >= v.Rank then
            table.insert(sortedVehicles, {name = k, vehicle = v})
        end
    end
    table.sort(sortedVehicles, function(a, b)
        return math.abs(PlayerJob.grade.level - a.vehicle.Rank) < math.abs(PlayerJob.grade.level - b.vehicle.Rank)
    end)
    for i = 1, #sortedVehicles do
        local k, v = sortedVehicles[i].name, sortedVehicles[i].vehicle
        local priceText = (v.TotalPrice ~= 0) and (v.TotalPrice .. "$") or "Free"
        table.insert(VehicleMenu, {
            header = "Purchase " .. k,
            txt = "Purchase: " .. k .. "<br> For: " .. priceText,
            icon = "fa-solid fa-circle-check",
            params = {
                event = "JobGarage:StartPreview",
                args = {
                    price = v.TotalPrice,
                    vehiclename = k,
                    vehicle = v.Vehicle,
                    trunkitems = v.VehicleSettings['TrunkItems'],
                    extras = v.VehicleSettings['DefaultExtras'],
                    liveries = v.VehicleSettings['DefaultLiveries'],
                    coordsinfo = data.coordsinfo,
                    station = data.station,
                    job = data.job,
                    useownable = data.useownable,
                    useliveries = data.useliveries,
                    rank = v.Rank,
                    useextras = data.useextras,
                    usepurchasable = data.usepurchasable,
                    userent = data.userent,
                    rentvehicles = data.rentvehicles,
                    purchasevehicles = data.purchasevehicles,
                }
            }
        })
    end
    table.insert(VehicleMenu, {
        header = "Go Back",
        icon = "fa-solid fa-left-long",
        params = {
            event = "JobGarage:OpenMainMenu",
            args = {
                userent = data.userent,
                rentvehicles = data.rentvehicles,
                purchasevehicles = data.purchasevehicles,
                coordsinfo = data.coordsinfo,
                rjob = data.job,
                station = data.station,
                useownable = data.useownable,
                useextras = data.useextras,
                usepurchasable = data.usepurchasable,
                useliveries = data.useliveries,
            },
        },
    })
    OpenOxMenu(VehicleMenu, data.station .. "VehicleMenu")
end)

RegisterNetEvent("JobGarage:OpenNearMenu", function(data)
    local PlayersMenu = {
        {
            header = "Nearby Players",
            icon = "fa-solid fa-circle-info",
            isMenuHeader = true,
        }
    }
    table.insert(PlayersMenu, {
        header = "You",
        txt = "Purchase " .. data.vehiclename .. " for yourself",
        icon = "fa-solid fa-user-check",
        params = {
            isServer = true,
            event = "JobGarage:BuyVehicle",
            args = {
                id = tonumber(GetPlayerServerId(PlayerId())),
                name = GetPlayerName(PlayerId()),
                buyer = tonumber(GetPlayerServerId(PlayerId())),
                paymenttype = data.paymenttype, 
                price = data.price,
                vehiclename = data.vehiclename,
                vehicle = data.vehicle,
                coordsinfo = data.coordsinfo,
                rank = data.rank,
                job = data.job,
                station = data.station,
                useownable = data.useownable,
                extras = data.extras,
                trunkitems = data.trunkitems,
                liveries = data.liveries,
            },
        }
    })
    local nearby = GetNearbyPlayers(PlayerPedId(), Config.CompanyFunds['CheckDistance'])
    if not nearby then
        table.insert(PlayersMenu, {
            header = "No Nearby Players",
            icon = "fa-solid fa-user-check",
            isMenuHeader = true,
        })
    else
        for k, v in pairs(nearby) do
            table.insert(PlayersMenu, {
                header = v.name,
                txt = "Purchase " .. data.vehiclename .. " for " .. v.name,
                icon = "fa-solid fa-user-check",
                params = {
                    isServer = true,
                    event = "JobGarage:BuyVehicle",
                    args = {
                        id = v.id,
                        name = v.name,
                        buyer = tonumber(GetPlayerServerId(PlayerId())),
                        paymenttype = data.paymenttype, 
                        price = data.price,
                        vehiclename = data.vehiclename,
                        vehicle = data.vehicle,
                        coordsinfo = data.coordsinfo,
                        rank = data.rank,
                        job = data.job,
                        station = data.station,
                        useownable = data.useownable,
                        extras = data.extras,
                        trunkitems = data.trunkitems,
                        liveries = data.liveries,
                    },
                }
            })
        end
    end
    table.insert(PlayersMenu, {
        header = "Go Back",
        icon = "fa-solid fa-left-long",
        params = {
            event = "JobGarage:ChoosePayment",
            args = {
                price = data.price,
                vehiclename = data.vehiclename,
                vehicle = data.vehicle,
                coordsinfo = data.coordsinfo,
                job = data.job,
                station = data.station,
                rank = data.rank,
                useownable = data.useownable,
                trunkitems = data.trunkitems,
                extras = data.extras,
                liveries = data.liveries,
            },
        },
    })
    OpenOxMenu(PlayersMenu, data.station .. "PlayersMenu")
end)

RegisterNetEvent("JobGarage:SpawnRentedVehicle", function(vehicle, vehiclename, amount, time, realtime, spawncoords, paymenttype, job, station)
    QBCore.Functions.SpawnVehicle(vehicle, function(veh)
        local player = PlayerPedId()
        SetVehicleDirtLevel(veh, 0.0)
        PlayerRentedVehicle[player] = {vehicle = veh, station = station, name = vehiclename, amount = amount, paymenttype = paymenttype, time = time, starttime = realtime, job = job}
        SetVehicleNumberPlateText(veh, FormatString(station) .. tostring(math.random(1000, 9999)))
        exports[Config.FuelSystem]:SetFuel(veh, 100.0)
        TaskWarpPedIntoVehicle(player, veh, -1)
        TriggerEvent("vehiclekeys:client:SetOwner", QBCore.Functions.GetPlate(veh))
        SetVehicleEngineOn(veh, true, true)
        StartLoop(veh, vehiclename, time, player, station)
    end, spawncoords, true)
end)

RegisterNetEvent("JobGarage:SpawnPurchasedVehicle", function(vehicle, spawncoords, checkradius, job, useownable, trunkitems, extras, liveries, station)
    QBCore.Functions.SpawnVehicle(vehicle, function(veh)
        SetVehicleNumberPlateText(veh, FormatString(station) .. tostring(math.random(1000, 9999)))
        exports[Config.FuelSystem]:SetFuel(veh, 100.0)
        TaskWarpPedIntoVehicle(PlayerPedId(), veh, -1)
        SetVehicleModKit(veh, 0)
        SetVehicleDirtLevel(veh, 0.0)
        TriggerEvent("vehiclekeys:client:SetOwner", QBCore.Functions.GetPlate(veh))
        SetVehicleEngineOn(veh, true, true)
        if trunkitems then
            TriggerServerEvent("inventory:server:addTrunkItems", QBCore.Functions.GetPlate(veh), SetTrunkItemsInfo(trunkitems))
        end
        if extras then
            for i = 0, 13 do
                if DoesExtraExist(veh, i) then
                    SetVehicleExtra(veh, i, 1)
                end
            end
            for i = 1, #extras do
                local extra = extras[i]
                if DoesExtraExist(veh, extra) then
                    SetVehicleExtra(veh, extra, 0)
                end
            end
        end
        if liveries then
            local matchedLivery = nil
            for k, v in pairs(liveries) do
                if PlayerJob.grade.level >= v.RankRequired then
                    if not matchedLivery then
                        matchedLivery = {name = k, data = v}
                    end
                end
            end
            if matchedLivery then
                SetVehicleLivery(veh, matchedLivery.data.LiveryID)
                Citizen.Wait(5000)
                QBCore.Functions.Notify(Config.Locals['Notifications']['LiverySet'] .. matchedLivery.name, "success")
            end
        end
        if useownable then
            TriggerServerEvent("JobGarage:AddData", "vehiclepurchased", vehicle, GetHashKey(veh), QBCore.Functions.GetPlate(veh), job)
        end
    end, spawncoords, true)
end)

RegisterNetEvent("JobGarage:ReturnRentedVehicle", function()
    local player = PlayerPedId()
    if not PlayerRentedVehicle[player] then
        QBCore.Functions.Notify(Config.Locals['Notifications']['IncorrectVehicle'] .. PlayerRentedVehicle[player].vehiclename, "error")
        return
    end
    if IsPedInAnyVehicle(player, false) then
        QBCore.Functions.TriggerCallback('JobGarage:GetRealTime', function(result)
            if not PlayerRentedVehicle[player] then
                QBCore.Functions.Notify(Config.Locals['Notifications']['NoRentedVehicle'])
                return
            end
            TaskLeaveVehicle(player, PlayerRentedVehicle[player].vehicle, 1)
            Citizen.Wait(2000)
            local remainingTime = (PlayerRentedVehicle[player].time * 60) - (result - PlayerRentedVehicle[player].starttime)
            local refund = math.floor(PlayerRentedVehicle[player].amount * (remainingTime / (PlayerRentedVehicle[player].time * 60)))
            QBCore.Functions.Notify(Config.Locals['Notifications']['VehicleReturned'] .. PlayerRentedVehicle[player].name .. " Refund amount : " .. refund .. "$")
            TriggerServerEvent("JobGarage:RefundRent", PlayerRentedVehicle[player].paymenttype, refund, GetPlayerServerId(PlayerId()), PlayerRentedVehicle[player].job)
            DeleteVehicle(PlayerRentedVehicle[player].vehicle)
            DeleteEntity(PlayerRentedVehicle[player].vehicle)
            PlayerRentedVehicle[player] = nil
        end)
    else
        QBCore.Functions.Notify(Config.Locals['Notifications']['NotInVehicle'], "error")
    end
end)

RegisterNetEvent("JobGarage:StartSelection", function(data)
    local player = PlayerPedId()
    if GetPedInVehicleSeat(data.vehicle, -1) == player then
        if QBCore.Functions.SpawnClear(vector3(data.coordsinfo['PreviewSpawn'].x, data.coordsinfo['PreviewSpawn'].y, data.coordsinfo['PreviewSpawn'].z), data.coordsinfo['CheckRadius']) then
            DoScreenFadeOut(700)
            while not IsScreenFadedOut() do
                Citizen.Wait(0)
            end
            SetPedCoordsKeepVehicle(player, data.coordsinfo['PreviewSpawn'].x, data.coordsinfo['PreviewSpawn'].y, data.coordsinfo['PreviewSpawn'].z)
            SetEntityHeading(data.vehicle, data.coordsinfo['PreviewSpawn'].w)
            PlaceObjectOnGroundProperly(data.vehicle)
            FreezeEntityPosition(data.vehicle, true)
            SetEntityCollision(data.vehicle, false, true)
            DoScreenFadeIn(700)
            if data.type == "livery" then
                local oldLivery = GetVehicleLivery(data.vehicle)
                local currentLivery = oldLivery
                Citizen.CreateThread(function()
                    while true do
                        ShowHelpNotification("Switch livery ~INPUT_PICKUP~. Confirm ~INPUT_MOVE_DOWN_ONLY~. Cancel ~INPUT_FRONTEND_RRIGHT~")
                        if IsControlJustReleased(0, 177) then
                            FreezeEntityPosition(data.vehicle, false)
                            SetEntityCollision(data.vehicle, true, true)
                            SetVehicleLivery(data.vehicle, oldLivery)
                            break
                        end
                        if IsControlJustReleased(0, 31) then
                            SetVehicleLivery(data.vehicle, currentLivery)
                            FreezeEntityPosition(data.vehicle, false)
                            SetEntityCollision(data.vehicle, true, true)
                            QBCore.Functions.Notify(Config.Locals['Notifications']['LiverySet'] .. currentLivery, "success")
                            break
                        end
                        if IsControlJustReleased(0, 51) then
                            currentLivery = (currentLivery + 1) % (GetVehicleLiveryCount(data.vehicle) - 1)
                            if currentLivery == 0 then
                                currentLivery = 1
                            end
                            SetVehicleLivery(data.vehicle, currentLivery)
                        end
                        if not IsPedInAnyVehicle(player) then
                            FreezeEntityPosition(data.vehicle, false)
                            SetEntityCollision(data.vehicle, true, true)
                            SetVehicleLivery(data.vehicle, oldLivery)
                            QBCore.Functions.Notify(Config.Locals['Notifications']['LeftVehicle'], "error")
                            break
                        end
                        Wait(0)
                    end
                end)
            end
        else
            QBCore.Functions.Notify(Config.Locals["Notifications"]["VehicleInSpawn"], "error")
        end
    else
        QBCore.Functions.Notify(Config.Locals["Notifications"]["NotDriver"], "error")
    end
end)

RegisterNetEvent("JobGarage:VehicleExtra", function(data)
    local Data = {
        userent = data.userent,
        rentvehicles = data.rentvehicles,
        purchasevehicles = data.purchasevehicles,
        coordsinfo = data.coordsinfo,
        job = data.job,
        station = data.station,
        useownable = data.useownable,
        useextras = data.useextras,
        usepurchasable = data.usepurchasable,
        useliveries = data.useliveries,
        vehicle = data.vehicle,
    }
    if IsVehicleExtraTurnedOn(data.vehicle, data.extraid) then
        QBCore.Functions.Notify(data.extraid .. Config.Locals['Notifications']['ExtraTurnedOff'])
        SetVehicleExtra(data.vehicle, data.extraid, 1)
        TriggerEvent("JobGarage:OpenExtrasMenu", Data)
    else
        QBCore.Functions.Notify(data.extraid .. Config.Locals['Notifications']['ExtraTurnedOn'])
        SetVehicleExtra(data.vehicle, data.extraid, 0)
        TriggerEvent("JobGarage:OpenExtrasMenu", Data)
    end
end)

RegisterNetEvent("JobGarage:StartPreview", function(data)
    local player = PlayerPedId()
    if QBCore.Functions.SpawnClear(vector3(data.coordsinfo['PreviewSpawn'].x, data.coordsinfo['PreviewSpawn'].y, data.coordsinfo['PreviewSpawn'].z), data.coordsinfo['CheckRadius']) then
        if not IsCamActive(VehicleCam) then
            QBCore.Functions.SpawnVehicle(data.vehicle, function(veh)
                SetEntityVisible(player, false, 1)
                if Config.SetVehicleTransparency == 'low' then
                    SetEntityAlpha(veh, 200)
                elseif Config.SetVehicleTransparency == 'medium' then
                    SetEntityAlpha(veh, 150)
                elseif Config.SetVehicleTransparency == 'high' then
                    SetEntityAlpha(veh, 100)
                elseif Config.SetVehicleTransparency == 'none' then
                    SetEntityAlpha(veh, 255)
                end
                FreezeEntityPosition(player, true)
                SetVehicleNumberPlateText(veh, "LSPD" .. tostring(math.random(1000, 9999)))
                exports[Config.FuelSystem]:SetFuel(veh, 0.0)
                SetVehicleDirtLevel(veh, 0.0)
                FreezeEntityPosition(veh, true)
                SetVehicleModKit(veh, 0)
                SetEntityCollision(veh, false, true)
                SetVehicleEngineOn(veh, false, false)
                if data.extras then
                    for i = 0, 13 do
                        if DoesExtraExist(veh, i) then
                            SetVehicleExtra(veh, i, 1)
                        end
                    end
                    for i = 1, #data.extras do
                        local extra = data.extras[i]
                        if DoesExtraExist(veh, extra) then
                            SetVehicleExtra(veh, extra, 0)
                        end
                    end
                end
                if data.liveries then
                    local matchedLivery = nil
                    for k, v in pairs(data.liveries) do
                        if PlayerJob.grade.level >= v.RankRequired then
                            if not matchedLivery then
                                matchedLivery = v
                            end
                        end
                    end
                    if matchedLivery then
                        SetVehicleLivery(veh, matchedLivery.LiveryID)
                    end
                end
                DoScreenFadeOut(200)
                Citizen.Wait(500)
                DoScreenFadeIn(200)
                SetVehicleUndriveable(veh, true)
                VehicleCam = CreateCamWithParams("DEFAULT_SCRIPTED_CAMERA", data.coordsinfo['CameraInformation']['CameraCoords'].x, data.coordsinfo['CameraInformation']['CameraCoords'].y, data.coordsinfo['CameraInformation']['CameraCoords'].z, data.coordsinfo['CameraInformation']['CameraRotation'].x, data.coordsinfo['CameraInformation']['CameraRotation'].y, data.coordsinfo['CameraInformation']['CameraRotation'].z, data.coordsinfo['CameraInformation']['CameraFOV'], false, 0)
                SetCamActive(VehicleCam, true)
                RenderScriptCams(true, true, 500, true, true)
                Citizen.CreateThread(function()
                    while IsCamActive(VehicleCam) do
                        ShowHelpNotification("~INPUT_PICKUP~ to confirm your purchase. ~INPUT_CELLPHONE_CANCEL~ To cancel")
                        if IsControlJustReleased(0, 177) then
                            SetEntityVisible(player, true, 1)
                            FreezeEntityPosition(player, false)
                            PlaySoundFrontend(-1, "NO", "HUD_FRONTEND_DEFAULT_SOUNDSET", 1)
                            QBCore.Functions.DeleteVehicle(veh)
                            DoScreenFadeOut(200)
                            Citizen.Wait(500)
                            DoScreenFadeIn(200)
                            SetCamActive(VehicleCam, false)
                            RenderScriptCams(false, false, 1, true, true)
                            local Data = {
                                userent = data.userent,
                                rentvehicles = data.rentvehicles,
                                purchasevehicles = data.purchasevehicles,
                                coordsinfo = data.coordsinfo,
                                job = data.job,
                                station = data.station,
                                useownable = data.useownable,
                                useextras = data.useextras,
                                usepurchasable = data.usepurchasable,
                                useliveries = data.useliveries,
                            }
                            TriggerEvent("JobGarage:OpenMainMenu", Data)
                            break
                        end
                        if IsControlJustReleased(0, 38) then
                            SetEntityVisible(player, true, 1)
                            FreezeEntityPosition(player, false)
                            PlaySoundFrontend(-1, "NO", "HUD_FRONTEND_DEFAULT_SOUNDSET", 1)
                            QBCore.Functions.DeleteVehicle(veh)
                            DoScreenFadeOut(200)
                            Citizen.Wait(500)
                            DoScreenFadeIn(200)
                            SetCamActive(VehicleCam, false)
                            RenderScriptCams(false, false, 1, true, true)
                            local VehicleData = {
                                price = data.price,
                                vehiclename = data.vehiclename,
                                vehicle = data.vehicle,
                                coordsinfo = data.coordsinfo,
                                job = data.job,
                                station = data.station,
                                rank = data.rank,
                                useownable = data.useownable,
                                trunkitems = data.trunkitems,
                                extras = data.extras,
                                liveries = data.liveries,
                            }
                            TriggerEvent("JobGarage:ChoosePayment", VehicleData)
                            break
                        end
                        Citizen.Wait(1)
                    end
                end)
            end, data.coordsinfo['PreviewSpawn'], true)
        end
    else
        QBCore.Functions.Notify(Config.Locals["Notifications"]["VehicleInSpawn"], "error")
    end
end)

RegisterNetEvent("JobGarage:ChooseRent", function(data)
    local minutes = OxInputDialog("Enter Number Of Minutes", {
        { type = "input", label = "Minutes", description = "Enter the number of minutes", required = true }
    })
    if minutes then
        local minutesamount = tonumber(minutes[1])
        if minutesamount and minutesamount > 0 and minutesamount <= Config.RentMaximum then
            local paymentType = OxInputDialog("Choose Payment Type", {
                { type = "radio", label = "Payment Type", options = {
                    { value = "cash", label = "Cash" },
                    { value = "bank", label = "Bank" }
                }, required = true }
            })
            if paymentType then
                local finalPrice = (minutesamount * data.price)
                local price = OxInputDialog("Final Price", {
                    { type = "checkbox", label = "Final Price: $" .. finalPrice, options = { { value = "agree", label = "Confirm Price", default = true } } }
                })
                if price then
                    TriggerServerEvent("JobGarage:RentVehicle", paymentType[1], finalPrice, data.vehiclename, data.vehicle, minutesamount, data.coordsinfo, data.job, data.station)
                end
            end
        else
            QBCore.Functions.Notify("Invalid amount! Minutes must be more than 0 and less than " .. Config.RentMaximum .. ". Minutes chosen: " .. (minutes[1] or "0"), "error")
        end
    end
end)

RegisterNetEvent("JobGarage:ChoosePayment", function(data)
    local jobText = (type(data.job) == "table" and data.job.name) and data.job.name or tostring(data.job)
    
    local paymentOptions = {
        { value = "cash", label = "Cash" },
        { value = "bank", label = "Bank" },
    }
    if PlayerJob.isboss and Config.CompanyFunds['Enable'] then
        table.insert(paymentOptions, { value = "company", label = "Company Funds" })
    end

    local inputs = {
        {
            type = "input",
            label = "Vehicle:",
            default = data.vehiclename,
            disabled = true,
            required = false,
        },
        {
            type = "input",
            label = "Price:",
            default = ("$" .. data.price),
            disabled = true,
            required = false,
        },
        {
            type = "select",
            label = "Payment Type",
            options = paymentOptions,
            required = true,
        },
    }

    local response = OxInputDialog("Confirm Purchase", inputs)
    if response then
        local chosenPayment = response[3]
        if chosenPayment then
            if chosenPayment == "company" and PlayerJob.isboss and Config.CompanyFunds['Enable'] then
                TriggerEvent("JobGarage:OpenNearMenu", {
                    paymenttype = chosenPayment,
                    price = data.price,
                    vehiclename = data.vehiclename,
                    vehicle = data.vehicle,
                    coordsinfo = data.coordsinfo,
                    job = data.job,
                    station = data.station,
                    rank = data.rank,
                    useownable = data.useownable,
                    trunkitems = data.trunkitems,
                    extras = data.extras,
                    liveries = data.liveries,
                })
            else
                TriggerServerEvent("JobGarage:BuyVehicle", {
                    paymenttype = chosenPayment,
                    price = data.price,
                    vehiclename = data.vehiclename,
                    vehicle = data.vehicle,
                    coordsinfo = data.coordsinfo,
                    job = data.job,
                    station = data.station,
                    useownable = data.useownable,
                    extras = data.extras,
                    trunkitems = data.trunkitems,
                    liveries = data.liveries,
                })
            end
        else
            QBCore.Functions.Notify("Purchase canceled", "error")
        end
    else
        QBCore.Functions.Notify("Purchase canceled", "error")
    end
end)
