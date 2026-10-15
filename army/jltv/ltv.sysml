// Light tactical vehicle powertrain trade: the fielded diesel JLTV against the diesel-electric
// hybrid eJLTV. Every figure is from a public source, cited on its line by key:
//   W1  Wikipedia, "Joint Light Tactical Vehicle", retrieved 2026-09-25
//   W2  Wikipedia, "Humvee replacement process", retrieved 2026-09-25
//   O1  Oshkosh Defense, "JLTV & eJLTV" product page, retrieved 2026-09-25
//   O2  Oshkosh Defense, "Oshkosh Defense unveils first-ever silent drive hybrid electric JLTV", 2022-01-25
//   B1  Breaking Defense, "Oshkosh Defense announces first hybrid electric JLTV", 2022-01-25
//   D1  Defense News, "Oshkosh unveils hybrid electric Joint Light Tactical Vehicle", 2022-01-25
//   J1  Janes, "Oshkosh Defense builds hybrid-electric JLTV demonstrator", 2022-01-26
//   C1  CRS RS22942, "Joint Light Tactical Vehicle (JLTV): Background and Issues for Congress", 2020-02-18
//   C2  CRS IF11729, "Joint Light Tactical Vehicle (JLTV)", 2025-05-19
// The evidence items at the end carry each source's URI.

package LTV {
    doc /* Powertrain trade for a light tactical vehicle of the JLTV class: keep the fielded
           diesel, or adopt the diesel-electric hybrid. */

    private import ScalarValues::*;
    private import ISQ::*;
    private import SI::*;
    private import USCustomaryUnits::*;

    // Tags: the graph reads a tag as a kind (demo/ontology.json adds ground-vehicle classes),
    // a relation, or a validity interval.
    metadata def Vendor;
    metadata def Evidence;
    metadata def Risk;
    metadata def Decision;
    metadata def Assumption;
    metadata def Supplies;
    metadata def Supports;
    metadata def Contradicts;
    metadata def Threatens;
    metadata def Supersedes;
    metadata def Validity {
        attribute since : String;
        attribute until : String;
    }

    // Structure.

    port def Shaft {
        doc /* Mechanical drive: torque out of the powertrain into the axles. */
    }
    port def Outlet {
        doc /* Electrical export power for mission equipment. */
    }

    interface def Driveline {
        end port source : Shaft;
        end port sink : ~Shaft;
    }
    interface def Bus {
        end port source : Outlet;
        end port sink : ~Outlet;
    }

    part def Engine;
    part def Transmission;
    part def Battery {
        attribute energy : EnergyValue;
    }
    part def Axle {
        port input : ~Shaft;
    }
    part def Equipment {
        doc /* Mission equipment that draws export power: radios, sensors, command post. */
        port inlet : ~Outlet;
    }

    part def Powertrain {
        doc /* Engine, transmission and any electric drive: moves the vehicle and powers its
               mission equipment. */
        port shaft : Shaft;
        port outlet : Outlet;
        attribute power : PowerValue;        // rated engine power
        attribute torque : TorqueValue;      // peak engine torque
        attribute export : PowerValue;       // export electrical power
        attribute silent : DurationValue;    // silent drive endurance
        attribute economy : Real;            // fuel economy gain over the fielded diesel, percent
    }

    part def Diesel :> Powertrain {
        doc /* Fielded JLTV powertrain: Gale Banks Engineering 866T V8 turbodiesel, based on the
               GM Duramax L5P, and an Allison 2500SP automatic (W1). */
        part engine : Engine {
            attribute displacement = 6.6 [L];     // W1: 6.6 L Gale Banks Engineering 866T V8
        }
        part transmission : Transmission {
            attribute gears = 6;                  // W1: Allison 2500SP 6-speed automatic
        }
        attribute :>> power = 400 [hp];           // W1: 400 hp (298 kW)
        attribute :>> torque = 850 [lbf*ft];      // W1: 850 lb-ft (1,152 N-m)
    }

    part def Hybrid :> Powertrain {
        @Validity { since = "2022-01-25"; }       // O2: unveiled 2022-01-25
        doc /* Diesel-electric hybrid eJLTV: a lithium-ion battery the diesel recharges while
               driving, for silent drive, silent watch and export power without a towed
               generator. */
        part engine : Engine;
        part battery : Battery {
            attribute :>> energy = 30 [kW*h];     // O2: battery capacity of 30 kWh
            attribute life = 10 [yr];             // D1: designed for a minimum of 10 years
        }
        attribute :>> export = 115 [kW];          // O2: export power capacity of up to 115 kW
        attribute :>> silent = 30 [min];          // B1: 30 minutes of silent drive
        attribute :>> economy = 20;               // O2: fuel economy improved by more than 20%
        attribute recharge = 30 [min];            // O2: fully recharges the battery within 30 minutes
        attribute added = 1000 [lb];              // J1: adds more than 1,000 lb to curb weight
    }

    part def Vehicle {
        doc /* A light tactical vehicle: the powertrain drives the axles and powers mission
               equipment. */
        attribute curb : MassValue;          // curb weight
        attribute gross : MassValue;         // gross vehicle weight
        attribute payload : MassValue;
        attribute range : LengthValue;
        attribute speed : SpeedValue;
        attribute mmbomf : LengthValue;      // mean miles between operational mission failure
        attribute cost : Real;               // unit cost, USD
        part powertrain : Powertrain;
        part axles : Axle [2];
        part equipment : Equipment;
        interface drive : Driveline connect powertrain.shaft to axles.input;
        interface feed : Bus connect powertrain.outlet to equipment.inlet;
    }

    part vehicle : Vehicle {
        doc /* The fielded four-door JLTV general purpose vehicle: curb and gross vehicle weight
               (GVW), payload, range, road speed, reliability and unit cost. */
        part :>> powertrain : Diesel;
        attribute :>> curb = 14000 [lb];          // W1: curb weight 14,000 lb
        attribute :>> gross = 22500 [lb];         // W1: gross weight 22,500 lb
        attribute :>> payload = 3500 [lb];        // O1: 4-door payload 3,500 lb
        attribute :>> range = 300 [mi];           // W1: range 300 mi
        attribute :>> speed = 70 [mi/h];          // W1: 70 mph on road
        attribute :>> mmbomf = 7051 [mi];         // W2: Oshkosh EMD vehicles, 7,051 MMBOMF
        attribute :>> cost = 370000;              // W1: unit cost $370,000-399,000 (low end)
    }

    // Requirements.

    requirement <'R1'> payload {
        doc /* Carry the four-door general purpose payload. */
        subject vehicle : Vehicle;
        attribute required = 3500 [lb];           // O1: 4-door payload 3,500 lb
        require constraint { vehicle.payload >= required }
    }
    requirement <'R2'> reliability {
        doc /* Mean miles between operational mission failure (MMBOMF) at or above the JLTV
               target. */
        subject vehicle : Vehicle;
        attribute required = 2400 [mi];           // W2: the target for JLTV is 2,400 MMBOMF
        require constraint { vehicle.mmbomf >= required }
    }
    requirement <'R3'> range {
        doc /* Operating range on internal fuel. */
        subject vehicle : Vehicle;
        attribute required = 300 [mi];            // W1: range 300 mi
        require constraint { vehicle.range >= required }
    }
    requirement <'R4'> transport {
        doc /* Air transportable: sling-loaded by CH-47 and CH-53 helicopters, carried by C-130
               aircraft (O1). */
        subject vehicle : Vehicle;
        assume constraint unchanged {
            doc /* The hybrid keeps the JLTV's dimensions and transportability, as Oshkosh
                   states (J1). */
        }
    }
    requirement <'R5'> power {
        doc /* Power mission equipment on board, without a towed generator. */
        subject vehicle : Vehicle;
    }
    requirement <'R6'> stealth {
        doc /* Silent drive and silent watch: move and hold position on battery with the engine
               off. */
        subject vehicle : Vehicle;
    }

    // The decision and its alternatives.

    #Decision analysis trade {
        doc /* Choose the powertrain for the light tactical vehicle: keep the fielded diesel or
               adopt the diesel-electric hybrid. */
        subject vehicle : Vehicle;
        part diesel : Diesel;
        part hybrid : Hybrid;
    }

    satisfy payload by trade.diesel;
    satisfy reliability by trade.diesel;
    satisfy range by trade.diesel;
    satisfy transport by trade.diesel;
    satisfy range by trade.hybrid;
    satisfy transport by trade.hybrid;
    satisfy power by trade.hybrid;
    satisfy stealth by trade.hybrid;

    // Verification.

    verification weighing {
        doc /* Weigh at curb and gross vehicle weight; load to rated payload. */
        subject vehicle : Vehicle;
        objective { verify payload; }
    }
    verification airlift {
        doc /* Sling-load certification under CH-47 and CH-53; C-130 load planning. */
        subject vehicle : Vehicle;
        objective { verify transport; }
    }
    verification durability {
        doc /* Reliability, availability and maintainability miles: score mission failures to
               compute MMBOMF; measure range on internal fuel. */
        subject vehicle : Vehicle;
        objective {
            verify reliability;
            verify range;
        }
    }
    verification bench {
        doc /* Load-bank export power; silent watch and silent drive on battery with the engine
               off. */
        subject vehicle : Vehicle;
        objective {
            verify power;
            verify stealth;
        }
    }

    // Vendors.

    #Vendor part oshkosh {
        doc /* Oshkosh Defense: JLTV producer from the 2015 award (W1); developer of the eJLTV (O2). */
    }
    #Vendor part amgeneral {
        doc /* AM General: JLTV follow-on producer from February 2023 (C2). */
    }
    #Vendor part banks {
        doc /* Gale Banks Engineering: the 866T V8 turbodiesel (W1). */
    }
    #Vendor part allison {
        doc /* Allison Transmission: the 2500SP automatic (W1). */
    }

    #Supplies dependency from oshkosh to Diesel {
        @Validity { since = "2015-08-25"; until = "2023-02-09"; }   // W1: awarded 2015-08-25; C2: follow-on awarded 2023-02-09
    }
    #Supplies dependency from oshkosh to Hybrid;
    #Supplies dependency from amgeneral to Diesel {
        @Validity { since = "2023-02-09"; }                          // C2: follow-on awarded 2023-02-09
    }
    #Supplies dependency from banks to Diesel::engine;
    #Supplies dependency from allison to Diesel::transmission;

    // Risks and assumptions.

    #Risk concern weight {
        doc /* The hybrid adds more than 1,000 lb of curb weight (J1): at the same gross vehicle
               weight it costs payload, and it narrows helicopter lift margin. */
    }
    #Risk concern maturity {
        doc /* The eJLTV was a demonstrator with no orders when unveiled (B1). */
    }
    #Risk concern procurement {
        @Validity { since = "2025-05-01"; }                          // C2: Army Transformation Initiative letter, 2025-05-01
        doc /* The Army ended JLTV procurement after its January 2025 tranche (C2). */
    }

    #Threatens dependency from weight to payload;
    #Threatens dependency from weight to transport;
    #Threatens dependency from weight to trade.hybrid;
    #Threatens dependency from maturity to trade.hybrid;
    #Threatens dependency from procurement to trade;

    #Assumption constraint cycle {
        doc /* The fuel economy gain of more than 20% (O2) holds over the Army duty cycle: a
               company figure, not an Army test result. */
    }
    #Supports dependency from cycle to trade.hybrid;

    // Evidence.

    #Evidence item <'W1'> wikipedia {
        doc /* Wikipedia, "Joint Light Tactical Vehicle": engine, power, torque, weights, range,
               speed, unit cost and contract awards. */
        attribute uri = "https://en.wikipedia.org/wiki/Joint_Light_Tactical_Vehicle";
    }
    #Evidence item <'W2'> replacement {
        doc /* Wikipedia, "Humvee replacement process": reliability of the EMD vehicles against
               the JLTV target, in MMBOMF. */
        attribute uri = "https://en.wikipedia.org/wiki/Humvee_replacement_process";
    }
    #Evidence item <'O1'> product {
        doc /* Oshkosh Defense, "JLTV & eJLTV": payload by door count and air transportability. */
        attribute uri = "https://oshkoshdefense.com/vehicles/light-tactical-vehicles/jltv/";
    }
    #Evidence item <'O2'> release {
        @Validity { since = "2022-01-25"; }
        doc /* Oshkosh Defense press release unveiling the eJLTV: battery, recharge, fuel economy
               and export power. */
        attribute uri = "https://oshkoshdefense.com/oshkosh-defense-unveils-first-ever-silent-drive-hybrid-electric-jltv/";
    }
    #Evidence item <'B1'> breaking {
        @Validity { since = "2022-01-25"; }
        doc /* Breaking Defense on the eJLTV: silent drive endurance; no orders at unveiling. */
        attribute uri = "https://breakingdefense.com/2022/01/oshkosh-defense-announces-first-hybrid-electric-jltv/";
    }
    #Evidence item <'D1'> news {
        @Validity { since = "2022-01-25"; }
        doc /* Defense News on the eJLTV: battery capacity and design life, export power. */
        attribute uri = "https://www.defensenews.com/land/2022/01/25/oshkosh-unveils-hybrid-electric-joint-light-tactical-vehicle/";
    }
    #Evidence item <'J1'> janes {
        @Validity { since = "2022-01-26"; }
        doc /* Janes on the eJLTV demonstrator: added curb weight; dimensions and
               transportability unchanged. */
        attribute uri = "https://www.janes.com/osint-insights/defence-news/land/oshkosh-defense-builds-hybrid-electric-jltv-demonstrator";
    }
    #Evidence item <'C1'> background {
        @Validity { since = "2020-02-18"; }
        doc /* CRS RS22942, quoting DOT&E's FY2018 report: all JLTVs are not operationally
               suitable because of deficiencies in reliability, maintainability, training,
               manuals, crew situational awareness and safety. */
        attribute uri = "https://www.everycrsreport.com/files/20200218_RS22942_9231b713562f5293806d3868ef892cbc6c6798c5.html";
    }
    #Evidence item <'C2'> status {
        @Validity { since = "2025-05-19"; }
        doc /* CRS IF11729: AM General follow-on award; the Army ends JLTV procurement. */
        attribute uri = "https://www.everycrsreport.com/files/2025-05-19_IF11729_b3d5f3f3f68c2c1d061e8befe0d0261fe8e4cbd3.html";
    }

    #Supports dependency from wikipedia to Diesel;
    #Supports dependency from wikipedia to vehicle;
    #Supports dependency from wikipedia to range;
    #Supports dependency from replacement to reliability;
    #Supports dependency from replacement to trade.diesel;
    #Supports dependency from product to payload;
    #Supports dependency from product to transport;
    #Supports dependency from release to Hybrid;
    #Supports dependency from breaking to Hybrid;
    #Supports dependency from news to Hybrid;
    #Supports dependency from janes to weight;
    #Supports dependency from janes to transport::unchanged;
    #Supports dependency from status to procurement;
    #Contradicts dependency from background to trade.diesel;
    #Supersedes dependency from status to background;
}
