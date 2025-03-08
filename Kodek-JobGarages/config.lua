Config = {}

Config.UseLogs = false -- Set to true to enable discord logs, using default QBCore logs system

Config.BanWhenExploit = false -- Set to true if you want to ban players / cheaters (Just another safety system)

Config.CompanyFunds = {
    Enable = false, -- Set to false to disable the company funds feature (Havent been tested completely. NOT recommended to use)
    CheckDistance = 10.0, -- The radius that the script checks for nearby players (If Enable)
}

Config.UseBlips = true -- Set to false to disable all script blips

Config.RentMaximum = 60 -- The rent maximum allowed in minutes

Config.Target = "qb-target" -- The name of your target

Config.FuelSystem = "cdn-fuel" -- The fuel system, LegacyFuel by default

Config.SetVehicleTransparency = 'none' -- The vehicle transparency level for the preview. Options : low, medium, high, none

Config.Locals = {
    Targets = {
        GarageTarget = {
            Distance = 5.0,
            Icon = "fa fa-car",
            Label = "Garage - ",  
        },
    },

    Notifications = {
        RentOver = "The rent time for ",
        RentWarning = "Return the vehicle or it will get deleted ! vehicle ",
        NoRentedVehicle = "There are no rented vehicles on your name",
        NoMoney = "You dont have enough money",
        VehicleReturned = "Vehicle returned. Vehicle ",
        SuccessfullyRented = " successfully rented for ",
        SuccessfullyBought = " successfully bought from ",
        NotDriver = "You must be the driver !",
        ExtraTurnedOn = " vehicle extra successfully got turned on",
        NoFunds = "There isnt enough funds for ",
        ExtraTurnedOff = " vehicle extra successfully got turned off",
        NoJob = " doesnt have the correct job",
        NoRank = " doesnt have the correct required rank",
        VehicleInSpawn = 'Theres a vehicle in the spawn area !',
        NotInVehicle = "You are not in any vehicle !",
        LiverySet = "Vehicle livery has been successfully set to ",
        LeftVehicle = "You have left the vehicle",
        IncorrectVehicle = "Incorrect vehicle ! you rented "
    },
}

Config.Locations = {
    Stations = {
        ["VMC"] = { -- Used as the station / garage name
            UseTarget = true, -- Set to false to use the Marker for this station
            UseRent = false, -- Set to false to disable the rent feature for this station
            UseOwnable = true, -- Set to false to disable ownable vehicles 
            UsePurchasable = true, -- Set to false to disable purchasable vehicles
            UseExtras = true, -- Set to false to disable the extras feature
            UseLiveries = true, -- Set to false to disable the livery menu
            JobRequired = "sams", -- The job required for this station garage
            VehiclesInformation = {
                PurchaseVehicles = { -- Purchasable vehicles
                    ["Brute Ambulance"] = {
                        Vehicle = "ambulance", -- The vehicle to spawn
                        TotalPrice = 5000, -- The total price it costs to buy this vehicle
                        Rank = 0, -- The rank required to purchase this vehicle
                        VehicleSettings = { -- Optional settings
                        },
                    },
                    ["Vapid Sadler Ambulance"] = {
                        Vehicle = "dlamb",
                        TotalPrice = 5000,
                        Rank = 0,
                        VehicleSettings = {
                        },
                    },
                    ["Vapid Speedo Ambulance"] = {
                        Vehicle = "emsnspeedo",
                        TotalPrice = 5000,
                        Rank = 0,
                        VehicleSettings = {
                        },
                    },
                    ["Bravado SAMS Buffalo"] = {
                        Vehicle = "dlbuffalo",
                        TotalPrice = 5000,
                        Rank = 0,
                        VehicleSettings = {
                        },
                    },
                    ["Declasse SAMS Granger"] = {
                        Vehicle = "dlgranger",
                        TotalPrice = 5000,
                        Rank = 0,
                        VehicleSettings = {
                        },
                    },
                },
                SpawnCoords = {
                    VehicleSpawn = vector4(-849.07, -1237.17, 6.68, 320.3),
                    PreviewSpawn = vector4(-849.07, -1237.17, 6.68, 320.3),
                    CheckRadius = 5.0,
                    CameraInformation = {
                        CameraCoords = vector3(-854.93, -1234.76, 8.53),
                        CameraRotation = vector3(-10.00, 0.00, 248.18),
                        CameraFOV = 70.0,
                    },
                },
            },
            GeneralInformation = {
                Blip = {
                    BlipId = 357,
                    BlipColour = 0,
                    BlipScale = 0.5,
                    Title = "SAMS - Garage"
                },
                TargetInformation = {
                    Ped = "s_m_y_xmech_01",
                    Coords = vector4(-848.06, -1247.02, 5.92, 2.03),
                    Scenario = "WORLD_HUMAN_CLIPBOARD"
                },
            },
        },
        ["Heli"] = { -- Used as the station / garage name
            UseTarget = true, -- Set to false to use the Marker for this station
            UseRent = false, -- Set to false to disable the rent feature for this station
            UseOwnable = true, -- Set to false to disable ownable vehicles 
            UsePurchasable = true, -- Set to false to disable purchasable vehicles
            UseExtras = true, -- Set to false to disable the extras feature
            UseLiveries = true, -- Set to false to disable the livery menu
            JobRequired = {"sast", "sams"}, -- The job required for this station garage
            VehiclesInformation = {
                PurchaseVehicles = { -- Purchasable vehicles
                    ["Buckingham Swift - SAMS"] = {
                        Vehicle = "dlswift", -- The vehicle to spawn
                        TotalPrice = 5000, -- The total price it costs to buy this vehicle
                        Rank = 0, -- The rank required to purchase this vehicle
                        VehicleSettings = { -- Optional settings
                        },
                    },
                    ["Buckingham Maverick"] = {
                        Vehicle = "polmav",
                        TotalPrice = 5000,
                        Rank = 0,
                        VehicleSettings = {
                            DefaultLiveries = { -- Default liveries that the player would be spawned if the player have the required rank.
                                ["Police"] = { -- The livery name for example : Supervisor, patrol ghost etc
                                    RankRequired = 0, -- The minimum required rank for this livery
                                    LiveryID = 1, -- The livery id
                                },                 
                                ["EMS"] = { -- The livery name for example : Supervisor, patrol ghost etc
                                    RankRequired = 0, -- The minimum required rank for this livery
                                    LiveryID = 5, -- The livery id
                                },
                            },
                        },
                    },
                },
                SpawnCoords = {
                    VehicleSpawn = vector4(-724.48, -1443.78, 5.0, 319.53),
                    PreviewSpawn = vector4(-724.48, -1443.78, 5.0, 319.53),
                    CheckRadius = 5.0,
                    CameraInformation = {
                        CameraCoords = vector3(-727.95, -1434.63, 8.03),
                        CameraRotation = vector3(-10.00, 0.00, 197.91),
                        CameraFOV = 70.0,
                    },
                },
            },
            GeneralInformation = {
                Blip = {
                    BlipId = 357,
                    BlipColour = 0,
                    BlipScale = 0.5,
                    Title = "DPS - Heli Garage"
                },
                TargetInformation = {
                    Ped = "s_m_y_pilot_01",
                    Coords = vector4(-696.54, -1400.15, 4.15, 232.09),
                    Scenario = "WORLD_HUMAN_CLIPBOARD"
                }
            }
        }
    }
}