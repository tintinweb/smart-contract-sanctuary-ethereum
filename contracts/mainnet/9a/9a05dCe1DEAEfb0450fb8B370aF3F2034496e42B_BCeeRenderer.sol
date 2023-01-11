// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

/*

                     :~7777777777777777777777!~.                 
                    :[email protected]@@@@@@@@@@@@@@@@@@@@@&5!                 
                 ^7Y555555555555555555555555555PPJ!.             
                [email protected]@G?^::^^^^^^^^^^^^^^^^^::~JB&#5!.            
                 [email protected]@G?^::^^^^^^^^^^^^~~^^^^^~~!7?5GGY~          
             .:^!JPGGY!^~!?JJJJJJJJ?!~^^~~~^^^[email protected]@&P?~:       
             ^Y#&BY!^^:^7P#@@@@@@@@GJ~^^^~^^^~JG&@@@@@@@#Y~      
             ~5&@#J~^!J555YYJJJJJYY555Y?!~!?Y555YYJ??JJYYYYJ7~.  
             ^Y#@BJ~!5&@BJ:   ..  [email protected]@[email protected]@G7.  ..   :J#@#J^  
             ^Y&@#J~!Y#@B?:.~YGP7:[email protected]@[email protected]@[email protected]#J^  
          .:~75GB57~!5#@B?:.~5BP?:[email protected]@[email protected]@P!.:[email protected]#J^  
         .7G&#P?~^^^75&@#J:  ...  [email protected]@[email protected]@G7.  ...  :J#@#J^  
      .~?Y5PG5?~^:^^!?YPP5YJJJ??JJJY5P5?!~!?5P5YYJ????JJYYYY?~.  
     .!P&@G?~^^~~~~~~^^~7P&@@@@@@@@GJ~^^^~^^^[email protected]@@@@@@@#Y~      
  .!YPP5YJ7!^^^~~~~~~^^^~7JYYYJJYYJ?!~^^~~~^^~!7J5#@@&P7^:       
  ^J#@&5~::^~~~~~~~~~~~~^^^^^^^^^^^^^~~~~~~~~~^:^!YG#P?^.        
  :[email protected]#5!^^^~~^^^^^~~~~~~^^^^^~~~~~~~~~~~~~~~~~~~~~~7JG#BY~      
  :[email protected]#5!^^^~!?JJ?7~^^^~!?JJ?!~^^~~~~~~~~~~~~~~~~^^:^[email protected]@P!      
  :[email protected]#5!^:^~7P&@BY!^:^~?G&@GJ~^^~~~~~~~~~~~~~~~~~^^[email protected]&5!      
  :[email protected]#5!^::~7P&@#Y!^:^[email protected]@BJ~^^~~~~~~~~~~~~~~~~^^:^[email protected]@P!      
  :[email protected]#5!^::~7P&@BY~^::~?G&@BJ~^^~~~~~~~~~~~~~~~~~~~7JG#BY~      
  :[email protected]#5!^::[email protected]@BJ~:.:^[email protected]@BJ~^^~~~~~~~~~~~~~^^^7YB#GJ~:.       
  :[email protected]#5!^^^~!JPGP5YJJJJYPGGY7~^^~~~~~~~~~~~~~^^^[email protected]@B7          
  :[email protected]#5!^^^~~^^!JG&@@@@BY7~^^~~~~~~~~~~~~~~~~^^^7P&@B?.         
  :[email protected]#5!^^^~^^^^!J5PPP5J7~^^^~~~~~~~~~~~~~~~~^^^7P&@G?:         
  :[email protected]#5!^^^~~~~~~^^^^^^^~~~~~~~~~~~~~~~~~~~~~^^^7P&@B?:         
  ^J#@&5~::^~~~~~~~^^^^^^~~~~~~~~~~~~~~~~~~~~~^:^[email protected]@B?:         
  :!YGG5J?7~^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^~!7?YPGGY!.         
     .!P&@G?~:^^^^^^^^^^^^^^^^^^^^^^^^^^^^^:^[email protected]#5~.            
      .!J55PPP55555PPPPPPPPPPPPPPPP555555PPPPPP5Y?~.             
         .7P&@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@&5~                 
          .^[email protected]@#[email protected]@GJ!!!!!^.                 
             ^Y#@G!                [email protected]&5^                        
             ^Y&@G7                [email protected]&5^                        
             ^Y&@@GY7~.           [email protected]@&PJ!^.                    
             ^[email protected]@@@#Y~            !5&@@@@G?:                    
             .^~7777!^.            :^!7777!^.                    

*/

import "./IBCeeRenderer.sol";
import "./library/image/Background.sol";
import "./library/image/Body.sol";
import "./library/image/Head.sol";
import "./library/image/Face.sol";
import "./library/image/Hands.sol";

contract BCeeRenderer is IBCeeRenderer {
    constructor(){}

    function constructImage(uint256 seed) external pure returns (string memory) {
        return string.concat(
            Background.constructBackground(seed),
            Body.constructBody(seed),
            Head.constructHead(seed),
            Face.constructFace(seed),
            Hands.constructHands(seed)
        );
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

library Hands {
    string constant internal NONE = "<path stroke=\"#000000\" d=\"M11 17h1M14 17h1M11 18h1M14 18h1M11 19h1M14 19h1M12 20h2\" />";
    string constant internal BAR = "<path stroke=\"#47080b\" d=\"M8 18h3M15 18h10M8 19h3M15 19h10\" />";
    string constant internal YELLOW_CARD = "<path stroke=\"#fff200\" d=\"M15 19h1M14 20h3M13 21h5M14 22h3M15 23h1\" />";
    string constant internal RED_CARD = "<path stroke=\"#ed1c24\" d=\"M15 19h1M14 20h3M13 21h5M14 22h3M15 23h1\" />";
    string constant internal FLAG = "<path stroke=\"#000000\" d=\"M13 12h3M13 13h1M16 13h1M13 14h3M13 15h1M12 16h3M15 17h1M15 18h1M12 19h3\" /><path stroke=\"#b5e61d\" d=\"M14 13h2\" />";
    string constant internal GOOD = "<path stroke=\"#000000\" d=\"M14 15h1M12 16h2M15 16h1M15 17h1M15 18h1M12 19h3\" />";
    string constant internal SICKLE = "<path stroke=\"#000000\" d=\"M11 17h1M14 17h1M4 18h8M14 18h15M4 19h8M14 19h13M28 19h1M12 20h2M28 20h1M28 21h1M27 22h2M27 23h1M26 24h2M25 25h2M23 26h3\" /><path stroke=\"#7f7f7f\" d=\"M27 19h1M27 20h1M26 21h2M26 22h1M25 23h2M24 24h2M23 25h2M22 26h1\" />";
    string constant internal MATCH = "<path stroke=\"#ed1c24\" d=\"M14 14h2\" /><path stroke=\"#b97a57\" d=\"M14 15h2M15 16h1M15 19h1M14 20h2\" /><path stroke=\"#000000\" d=\"M12 16h3M15 17h1M15 18h1M12 19h3\" />";
    string constant internal BRIEFCASE= "<path stroke=\"#000000\" d=\"M11 17h1M14 17h1M11 18h1M14 18h1M11 19h1M14 19h1M10 20h6M10 21h2M14 21h2M8 22h10M8 23h1M11 23h1M14 23h1M17 23h1M8 24h1M11 24h4M17 24h1M8 25h1M17 25h1M8 26h10\" /><path stroke=\"#7f7f7f\" d=\"M9 23h2M15 23h2M9 24h2M15 24h2M9 25h8\" /><path stroke=\"#c3c3c3\" d=\"M12 23h2\" />";
    string constant internal DAGGER = "<path stroke=\"#000000\" d=\"M11 17h1M14 17h1M16 17h1M9 18h3M14 18h3M9 19h3M14 19h3M12 20h2M16 20h1\" /><path stroke=\"#7f7f7f\" d=\"M17 18h8M17 19h6\" />";
    string constant internal HAMMER = "<path stroke=\"#000000\" d=\"M21 15h3M20 16h1M24 16h1M4 17h8M14 17h7M24 17h1M4 18h1M11 18h1M14 18h1M24 18h1M4 19h8M14 19h7M24 19h1M12 20h2M20 20h1M24 20h1M21 21h3\" /><path stroke=\"#ed1c24\" d=\"M21 16h3M21 17h3M20 18h4M21 19h3M21 20h3\" /><path stroke=\"#b97a57\" d=\"M5 18h6M15 18h5\" />";
    string constant internal HEART = "<path stroke=\"#ed1c24\" d=\"M14 14h2M17 14h2M14 15h5M15 16h3M16 17h1\" /><path stroke=\"#000000\" d=\"M12 16h3M15 17h1M15 18h1M12 19h3\" />";
    string constant internal GUN = "<path stroke=\"#000000\" d=\"M19 13h1M13 14h7M13 15h1M19 15h1M12 16h3M16 16h4M15 17h2M15 18h1M12 19h3\" /><path stroke=\"#7f7f7f\" d=\"M14 15h5M15 16h1\" />";

    function constructHands(uint256 seed) internal pure returns (string memory) {
        uint40 _seed = uint40(seed << 8*4);
        _seed = _seed >> 8*4;

        if (_seed >= 206) {
            return NONE;
        } else if (_seed >= 181) {
            return string.concat(
                NONE,
                BAR
            );
        } else if (_seed >= 156) {
            return string.concat(
                NONE,
                YELLOW_CARD
            );
        } else if (_seed >= 131) {
            return string.concat(
                NONE,
                RED_CARD
            );
        } else if (_seed >= 106) {
            return FLAG;
        } else if (_seed >= 81) {
            return GOOD;
        } else if (_seed >= 61) {
            return SICKLE;
        } else if (_seed >= 41) {
            return MATCH;
        } else if (_seed >= 31) {
            return BRIEFCASE;
        } else if (_seed >= 21) {
            return DAGGER;
        } else if (_seed >= 11) {
            return HAMMER;
        } else if (_seed >= 5) {
            return HEART;
        } else {
            return GUN;
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

library Face {
    string constant internal NORMAL_EYES_0 = "<path stroke=\"#000000\" d=\"M14 10h3M20 10h3M13 11h1M17 11h1M19 11h1M23 11h1M13 12h1M15 12h1M17 12h1M19 12h1M21 12h1M23 12h1M13 13h1M17 13h1M19 13h1M23 13h1M14 14h3M20 14h3\" /><path stroke=\"#f2f2f2\" d=\"M14 11h3M20 11h3M14 12h1M16 12h1M20 12h1M22 12h1M14 13h3M20 13h3\" />";
    string constant internal NORMAL_EYES_1 = "<path stroke=\"#000000\" d=\"M12 11h5M18 11h5M12 12h1M14 12h1M16 12h1M18 12h1M20 12h1M22 12h1M12 13h1M16 13h1M18 13h1M22 13h1M13 14h3M19 14h3\" /><path stroke=\"#f2f2f2\" d=\"M13 12h1M15 12h1M19 12h1M21 12h1M13 13h3M19 13h3\" />";
    string constant internal NORMAL_EYES_2 = "<path stroke=\"#000000\" d=\"M14 10h3M20 10h3M13 11h1M17 11h1M19 11h1M23 11h1M13 12h1M15 12h3M19 12h1M21 12h3M13 13h1M17 13h1M19 13h1M23 13h1M14 14h3M20 14h3\" /><path stroke=\"#f2f2f2\" d=\"M14 11h3M20 11h3M14 12h1M20 12h1M14 13h3M20 13h3\" />";
    string constant internal BLUE_EYES = "<path stroke=\"#000000\" d=\"M14 10h3M20 10h3M13 11h1M17 11h1M19 11h1M23 11h1M13 12h1M15 12h1M17 12h1M19 12h1M21 12h1M23 12h1M13 13h1M17 13h1M19 13h1M23 13h1M14 14h3M20 14h3\" /><path stroke=\"#3f48cc\" d=\"M14 11h3M20 11h3M14 12h1M16 12h1M20 12h1M22 12h1M14 13h3M20 13h3\" />";
    string constant internal INJURED_EYES = "<path stroke=\"#000000\" d=\"M14 10h3M20 10h3M13 11h1M17 11h1M19 11h1M23 11h1M13 12h1M17 12h1M19 12h1M23 12h1M13 13h1M17 13h1M19 13h1M23 13h1M14 14h3M20 14h3\" /><path stroke=\"#ed1c24\" d=\"M14 11h3M20 11h3M14 12h1M16 12h1M20 12h1M22 12h1M14 13h3M20 13h3\" /><path stroke=\"#730e11\" d=\"M15 12h1M21 12h1\" />";
    string constant internal MISMATCHED_EYES = "<path stroke=\"#000000\" d=\"M14 10h3M13 11h1M17 11h1M19 11h5M13 12h1M15 12h1M17 12h1M19 12h1M21 12h1M23 12h1M13 13h1M17 13h1M19 13h1M23 13h1M14 14h3M20 14h3\" /><path stroke=\"#f2f2f2\" d=\"M14 11h3M14 12h1M16 12h1M20 12h1M22 12h1M14 13h3M20 13h3\" />";
    string constant internal SUNGLASSES_GRAY = "<path stroke=\"#000000\" d=\"M13 10h4M18 10h4M10 11h4M16 11h3M21 11h1M10 12h1M13 12h1M16 12h1M18 12h1M21 12h1M13 13h4M18 13h4\" /><path stroke=\"#7f7f7f\" d=\"M14 11h2M19 11h2M14 12h2M19 12h2\" />";
    string constant internal SUNGLASSES_3D = "<path stroke=\"#000000\" d=\"M13 10h4M18 10h4M10 11h4M16 11h3M21 11h1M10 12h1M13 12h1M16 12h1M18 12h1M21 12h1M13 13h4M18 13h4\" /><path stroke=\"#ed1c24\" d=\"M14 11h2M14 12h2\" /><path stroke=\"#3f48cc\" d=\"M19 11h2M19 12h2\" />";
    string constant internal GOGGLES = "<path stroke=\"#000000\" d=\"M13 9h9M12 10h1M22 10h1M12 11h1M22 11h1M12 12h1M22 12h1M12 13h1M17 13h1M22 13h1M13 14h4M18 14h4\" /><path stroke=\"#7f7f7f\" d=\"M13 10h9M13 11h1M21 11h1M13 12h1M16 12h3M21 12h1M13 13h4M18 13h4\" /><path stroke=\"#c3c3c3\" d=\"M14 11h7M14 12h2M19 12h2\" />";
    string constant internal ERROR = "<path stroke=\"#000000\" opacity= \"0.3\" d=\"M10 10h1M12 10h1M14 10h1M16 10h1M18 10h1M20 10h1M22 10h1M11 11h1M13 11h1M15 11h1M17 11h1M19 11h1M21 11h1M23 11h1M10 12h1M12 12h1M14 12h1M16 12h1M18 12h1M20 12h1M22 12h1M11 13h1M13 13h1M15 13h1M17 13h1M19 13h1M21 13h1M23 13h1M10 14h1M12 14h1M14 14h1M16 14h1M18 14h1M20 14h1M22 14h1M11 15h1M13 15h1M15 15h1M17 15h1M19 15h1M21 15h1M23 15h1\" /><path stroke=\"#c3c3c3\" d=\"M11 10h1M13 10h1M15 10h1M17 10h1M19 10h1M21 10h1M23 10h1M10 11h1M12 11h1M14 11h1M16 11h1M18 11h1M20 11h1M22 11h1M11 12h1M13 12h1M15 12h1M17 12h1M19 12h1M21 12h1M23 12h1M10 13h1M12 13h1M14 13h1M16 13h1M18 13h1M20 13h1M22 13h1M11 14h1M13 14h1M15 14h1M17 14h1M19 14h1M21 14h1M23 14h1M10 15h1M12 15h1M14 15h1M16 15h1M18 15h1M20 15h1M22 15h1\" />";
    string constant internal SUNGLASSES_BLUE = "<path stroke=\"#000000\" d=\"M12 9h5M18 9h5M12 10h1M16 10h1M18 10h1M22 10h1M10 11h3M16 11h3M22 11h1M10 12h1M12 12h1M16 12h1M18 12h1M22 12h1M13 13h3M19 13h3\" /><path stroke=\"#1f388f\" d=\"M13 10h3M19 10h3\" /><path stroke=\"#294bbf\" d=\"M13 11h3M19 11h3\" /><path stroke=\"#325be8\" d=\"M13 12h3M19 12h3\" />";
    string constant internal BLACK_EYES = "<path stroke=\"#000000\" d=\"M20 10h3M13 11h5M19 11h1M23 11h1M13 12h2M16 12h2M19 12h1M21 12h1M23 12h1M13 13h5M19 13h1M23 13h1M14 14h3M20 14h3\" /><path stroke=\"#f2f2f2\" d=\"M20 11h3M15 12h1M20 12h1M22 12h1M20 13h3\" />";

    function constructFace(uint256 seed) internal pure returns (string memory) {
        uint40 _seed = uint40(seed << 8*3);
        _seed = _seed >> 8*4;

        if (_seed >= 226) {
            return NORMAL_EYES_0;
        } else if (_seed >= 196) {
            return NORMAL_EYES_1;
        } else if (_seed >= 166) {
            return NORMAL_EYES_2;
        } else if (_seed >= 136) {
            return BLUE_EYES;
        } else if (_seed >= 106) {
            return INJURED_EYES;
        } else if (_seed >= 86) {
            return MISMATCHED_EYES;
        } else if (_seed >= 66) {
            return SUNGLASSES_GRAY;
        } else if (_seed >= 46) {
            return SUNGLASSES_3D;
        } else if (_seed >= 26) {
            return GOGGLES;
        } else if (_seed >= 16) {
            return string.concat(
                NORMAL_EYES_0,
                ERROR
            );
        } else if (_seed >= 6) {
            return SUNGLASSES_BLUE;
        } else {
            return BLACK_EYES;
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

library Head {
    string constant internal NONE = " ";
    string constant internal THIN = "<path stroke=\"#000000\" d=\"M15 3h1M10 4h2M15 4h1M20 4h2M11 5h2M15 5h2M19 5h2M12 6h2M16 6h1M19 6h1M24 6h1M7 7h4M22 7h3M10 8h2M21 8h2M11 9h1\" />";
    string constant internal PERM = "<path stroke=\"#000000\" d=\"M13 2h8M11 3h12M9 4h15M8 5h16M8 6h17M8 7h5M20 7h5M8 8h4M21 8h4M8 9h4M22 9h3M8 10h3M23 10h2M8 11h3M23 11h2M9 12h2M23 12h1\" />";
    string constant internal CAP = "<path stroke=\"#000000\" d=\"M13 6h8M12 7h2M20 7h2M8 8h5M21 8h2M8 9h1M22 9h1M8 10h15\" /><path stroke=\"#7f7f7f\" d=\"M14 7h6M13 8h8M9 9h13\" />";
    string constant internal BANG = "<path stroke=\"#000000\" d=\"M23 1h1M25 1h1M23 2h1M25 2h1M23 3h1M25 3h1M23 4h1M25 4h1M23 6h1M25 6h1\" />";
    string constant internal PERM_YELLOW = "<path stroke=\"#000000\" d=\"M13 2h8M11 3h2M21 3h2M9 4h2M23 4h1M8 5h1M23 5h1M8 6h1M24 6h1M8 7h1M24 7h1M8 8h1M24 8h1M8 9h1M24 9h1M8 10h1M24 10h1M8 11h1M24 11h1M9 12h2M23 12h1\" /><path stroke=\"#fff200\" d=\"M13 3h8M11 4h12M9 5h14M9 6h15M9 7h4M20 7h4M9 8h3M21 8h3M9 9h3M22 9h2M9 10h2M23 10h1M9 11h2M23 11h1\" />";
    string constant internal RECTANGLE= "<path stroke=\"#000000\" d=\"M12 4h9M12 5h9M12 6h9M12 7h9\" />";
    string constant internal ANGEL_RING = "<path stroke=\"#fff200\" d=\"M12 3h9M11 4h2M20 4h2M12 5h9\" />";
    string constant internal CONE = "<path stroke=\"#000000\" d=\"M6 0h1M6 1h3M7 2h1M9 2h2M7 3h1M11 3h2M8 4h1M13 4h2M8 5h1M15 5h2M8 6h1M17 6h2M9 7h1M9 8h1M10 9h1M10 10h1\" /><path stroke=\"#ed1c24\" d=\"M8 2h1M8 3h2M9 4h4M10 5h3M14 5h1M9 6h2M12 6h5M10 7h3M10 8h2\" /><path stroke=\"#fff200\" d=\"M10 3h1M9 5h1M13 5h1M11 6h1M11 9h1\" />";
    string constant internal FEDORA = "<path stroke=\"#000000\" d=\"M14 3h6M13 4h4M20 4h1M13 5h3M20 5h1M10 6h6M21 6h3M10 7h8M23 7h1M10 8h14\" /><path stroke=\"#7f7f7f\" d=\"M17 4h3M16 5h4M16 6h5M18 7h5\" />";
    string constant internal HEART = "<path stroke=\"#ed1c24\" d=\"M14 0h2M17 0h2M13 1h1M16 1h1M19 1h1M13 2h1M19 2h1M14 3h1M18 3h1M15 4h1M17 4h1M16 5h1\" /><path stroke=\"#ffaec9\" d=\"M14 1h2M17 1h2M14 2h5M15 3h3M16 4h1\" />";
    string constant internal CROWN = "<path stroke=\"#000000\" d=\"M13 3h1M16 3h1M19 3h1M13 4h2M16 4h1M18 4h2M13 5h1M15 5h1M17 5h1M19 5h1M13 6h1M19 6h1\" /><path stroke=\"#fff200\" d=\"M14 5h1M16 5h1M18 5h1M14 6h5\" />";
    string constant internal CLOVER = "<path stroke=\"#000000\" d=\"M17 0h2M20 0h2M16 1h1M19 1h1M22 1h1M17 2h3M21 2h2M18 3h4M17 4h2M21 4h1M16 5h1M19 5h2M16 6h1\" /><path stroke=\"#22b14c\" d=\"M17 1h2M20 1h2M20 2h1M19 4h2\" />";

    function constructHead(uint256 seed) internal pure returns (string memory) {
        uint40 _seed = uint40(seed << 8*2);
        _seed = _seed >> 8*4;

        if (_seed >= 206) {
            return NONE;
        } else if (_seed >= 181) {
            return THIN;
        } else if (_seed >= 156) {
            return PERM;
        } else if (_seed >= 131) {
            return CAP;
        } else if (_seed >= 106) {
            return BANG;
        } else if (_seed >= 81) {
            return PERM_YELLOW;
        } else if (_seed >= 56) {
            return RECTANGLE;
        } else if (_seed >= 46) {
            return ANGEL_RING;
        } else if (_seed >= 36) {
            return CONE;
        } else if (_seed >= 26) {
            return FEDORA;
        } else if (_seed >= 16) {
            return HEART;
        } else if (_seed >= 6) {
            return CROWN;
        } else {
            return CLOVER;
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

library Body {
    string constant internal PREFIX = "<path stroke=\"#";
    string constant internal SUFFIX = "\" d=\"M13 8h7M13 9h8M12 10h10M12 11h10M12 12h10M11 13h10M10 14h11M9 15h12M9 16h13M9 17h13M9 18h13M9 19h12M9 20h12M9 21h12M9 22h12M10 23h10\" />";
    string constant internal BODY = "000000\" d=\"M13 7h7M12 8h1M20 8h1M12 9h1M21 9h1M11 10h1M22 10h1M11 11h1M22 11h1M11 12h1M22 12h1M10 13h1M21 13h1M9 14h1M21 14h1M8 15h1M21 15h1M8 16h1M22 16h1M8 17h1M22 17h1M8 18h1M22 18h1M8 19h1M21 19h1M8 20h1M21 20h1M8 21h1M21 21h1M8 22h1M21 22h1M9 23h1M20 23h1M10 24h10M11 25h1M17 25h1M11 26h1M17 26h1M11 27h2M17 27h2\" />";
    string constant internal SHADOW = "7f7f7f\" opacity= \"0.5\" d=\"M13 26h3M9 27h2M13 27h4M19 27h2M9 28h14M12 29h15M19 30h9\" />";
    string constant internal BEIGE = "efe4b0";
    string constant internal YELLOW = "fff200";
    string constant internal WHITE = "ffffff";
    string constant internal VIOLET = "ba9fbe";
    string constant internal GRAY = "c3c3c3";
    string constant internal GREEN = "756f0e";
    string constant internal BROWN = "b97a57";
    string constant internal PINK = "ffaec9";
    string constant internal RED = "ff575a";
    string constant internal PURPLE = "741b7c";
    string constant internal MUTANT = "c9ff20\" d=\"M13 8h4M18 8h2M13 9h1M15 9h6M13 10h7M21 10h1M12 11h10M12 12h3M16 12h6M11 13h7M19 13h2M10 14h1M12 14h9M9 15h12M9 16h3M13 16h7M21 16h1M9 17h6M16 17h1M18 17h4M9 18h1M11 18h11M9 19h12M9 20h3M13 20h3M17 20h1M19 20h2M9 21h12M10 22h8M19 22h2M10 23h2M13 23h7\" /><path stroke=\"#b5e61d\" d=\"M17 8h1M14 9h1M12 10h1M20 10h1M15 12h1M18 13h1M11 14h1M12 16h1M20 16h1M15 17h1M17 17h1M10 18h1M12 20h1M16 20h1M18 20h1M9 22h1M18 22h1M12 23h1\" />";
    string constant internal STRIPES_SUFFIX = "\" d=\"M13 8h1M15 8h1M17 8h1M19 8h1M13 9h1M15 9h1M17 9h1M19 9h1M13 10h1M15 10h1M17 10h1M19 10h1M21 10h1M13 11h1M15 11h1M17 11h1M19 11h1M21 11h1M13 12h1M15 12h1M17 12h1M19 12h1M21 12h1M11 13h1M13 13h1M15 13h1M17 13h1M19 13h1M11 14h1M13 14h1M15 14h1M17 14h1M19 14h1M9 15h1M11 15h1M13 15h1M15 15h1M17 15h1M19 15h1M9 16h1M11 16h1M13 16h1M15 16h1M17 16h1M19 16h1M21 16h1M9 17h1M11 17h1M13 17h1M15 17h1M17 17h1M19 17h1M21 17h1M9 18h1M11 18h1M13 18h1M15 18h1M17 18h1M19 18h1M21 18h1M9 19h1M11 19h1M13 19h1M15 19h1M17 19h1M19 19h1M9 20h1M11 20h1M13 20h1M15 20h1M17 20h1M19 20h1M9 21h1M11 21h1M13 21h1M15 21h1M17 21h1M19 21h1M9 22h1M11 22h1M13 22h1M15 22h1M17 22h1M19 22h1M11 23h1M13 23h1M15 23h1M17 23h1M19 23h1\" />";
    string constant internal STRIPES_OPT = "<path stroke=\"#858585\" d=\"M14 8h1M16 8h1M18 8h1M14 9h1M16 9h1M18 9h1M20 9h1M12 10h1M14 10h1M16 10h1M18 10h1M20 10h1M12 11h1M14 11h1M16 11h1M18 11h1M20 11h1M12 12h1M14 12h1M16 12h1M18 12h1M20 12h1M12 13h1M14 13h1M16 13h1M18 13h1M20 13h1M10 14h1M12 14h1M14 14h1M16 14h1M18 14h1M20 14h1M10 15h1M12 15h1M14 15h1M16 15h1M18 15h1M20 15h1M10 16h1M12 16h1M14 16h1M16 16h1M18 16h1M20 16h1M10 17h1M12 17h1M14 17h1M16 17h1M18 17h1M20 17h1M10 18h1M12 18h1M14 18h1M16 18h1M18 18h1M20 18h1M10 19h1M12 19h1M14 19h1M16 19h1M18 19h1M20 19h1M10 20h1M12 20h1M14 20h1M16 20h1M18 20h1M20 20h1M10 21h1M12 21h1M14 21h1M16 21h1M18 21h1M20 21h1M10 22h1M12 22h1M14 22h1M16 22h1M18 22h1M20 22h1M10 23h1M12 23h1M14 23h1M16 23h1M18 23h1\" />";
    string constant internal GRAY_STRIPES = "c3c3c3";
    string constant internal YELLOW_STRIPES = "efe4b0";
    string constant internal DARK = "0D0D0D";
    
    function constructBody(uint256 seed) internal pure returns (string memory) {
        uint40 _seed = uint40(seed << 8);
        _seed = _seed >> 8*4;
        string memory color;

        if (_seed >= 232) {
            color = BEIGE;
        } else if (_seed >= 208) {
            color = YELLOW;
        } else if (_seed >= 184) {
            color = WHITE;
        } else if (_seed >= 160) {
            color = VIOLET;
        } else if (_seed >= 136) {
            color = GRAY;
        } else if (_seed >= 112) {
            color = GREEN;
        } else if (_seed >= 88) {
            color = BROWN;
        } else if (_seed >= 64) {
            color = PINK;
        } else if (_seed >= 40) {
            color = RED;
        } else if (_seed >= 16) {
            color = PURPLE;
        } else if (_seed >= 12) {
            return string.concat(
                PREFIX,
                BODY,
                PREFIX,
                SHADOW,
                PREFIX,
                MUTANT
            );
        } else if (_seed >= 8) {
            return string.concat(
                PREFIX,
                BODY,
                PREFIX,
                SHADOW,
                PREFIX,
                GRAY_STRIPES,
                STRIPES_SUFFIX,
                STRIPES_OPT
            );
        } else if (_seed >= 4) {
            return string.concat(
                PREFIX,
                BODY,
                PREFIX,
                SHADOW,
                PREFIX,
                YELLOW_STRIPES,
                STRIPES_SUFFIX,
                STRIPES_OPT
            );
        } else {
            color = DARK;
        }

        return string.concat(
            PREFIX,
            BODY,
            PREFIX,
            SHADOW,
            PREFIX,
            color,
            SUFFIX
        );
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

library Background {
    string constant internal PREFIX = "<path stroke=\"#";
    string constant internal SUFFIX = "\" d=\"M0 0h32M0 1h32M0 2h32M0 3h32M0 4h32M0 5h32M0 6h32M0 7h32M0 8h32M0 9h32M0 10h32M0 11h32M0 12h32M0 13h32M0 14h32M0 15h32M0 16h32M0 17h32M0 18h32M0 19h32M0 20h32M0 21h32M0 22h32M0 23h32M0 24h32M0 25h32M0 26h32M0 27h32M0 28h32M0 29h32M0 30h32M0 31h32\" />";
    string constant internal NONE = "ffffff";
    string constant internal GRAY = "d9d9d9";
    string constant internal ORANGE = "ffc983";
    string constant internal GREEN = "7dffa4";
    string constant internal BLUE = "93c0fa";
    string constant internal RED = "ff8e90";
    string constant internal SKYBLUE = "c6eaed";
    string constant internal VIOLET = "a99cff";
    string constant internal HALF_YELLOW = "<path stroke=\"#ffffe8\" d=\"M0 0h32M0 1h31M0 2h30M0 3h29M0 4h28M0 5h27M0 6h26M0 7h25M0 8h24M0 9h23M0 10h22M0 11h21M0 12h20M0 13h19M0 14h18M0 15h17M0 16h16M0 17h15M0 18h14M0 19h13M0 20h12M0 21h11M0 22h10M0 23h9M0 24h8M0 25h7M0 26h6M0 27h5M0 28h4M0 29h3M0 30h2M0 31h1\" /><path stroke=\"#faffd1\" d=\"M31 1h1M30 2h2M29 3h3M28 4h4M27 5h5M26 6h6M25 7h7M24 8h8M23 9h9M22 10h10M21 11h11M20 12h12M19 13h13M18 14h14M17 15h15M16 16h16M15 17h17M14 18h18M13 19h19M12 20h20M11 21h21M10 22h22M9 23h23M8 24h24M7 25h25M6 26h26M5 27h27M4 28h28M3 29h29M2 30h30M1 31h31\" />";
    string constant internal HALF_PINK = "<path stroke=\"#ffe7e7\" d=\"M0 0h32M0 1h31M0 2h30M0 3h29M0 4h28M0 5h27M0 6h26M0 7h25M0 8h24M0 9h23M0 10h22M0 11h21M0 12h20M0 13h19M0 14h18M0 15h17M0 16h16M0 17h15M0 18h14M0 19h13M0 20h12M0 21h11M0 22h10M0 23h9M0 24h8M0 25h7M0 26h6M0 27h5M0 28h4M0 29h3M0 30h2M0 31h1\" /><path stroke=\"#ffcbcc\" d=\"M31 1h1M30 2h2M29 3h3M28 4h4M27 5h5M26 6h6M25 7h7M24 8h8M23 9h9M22 10h10M21 11h11M20 12h12M19 13h13M18 14h14M17 15h15M16 16h16M15 17h17M14 18h18M13 19h19M12 20h20M11 21h21M10 22h22M9 23h23M8 24h24M7 25h25M6 26h26M5 27h27M4 28h28M3 29h29M2 30h30M1 31h31\" />";
    string constant internal HALF_VIOLET = "<path stroke=\"#ffd4ff\" d=\"M0 0h32M0 1h31M0 2h30M0 3h29M0 4h28M0 5h27M0 6h26M0 7h25M0 8h24M0 9h23M0 10h22M0 11h21M0 12h20M0 13h19M0 14h18M0 15h17M0 16h16M0 17h15M0 18h14M0 19h13M0 20h12M0 21h11M0 22h10M0 23h9M0 24h8M0 25h7M0 26h6M0 27h5M0 28h4M0 29h3M0 30h2M0 31h1\" /><path stroke=\"#f2c9f2\" d=\"M31 1h1M30 2h2M29 3h3M28 4h4M27 5h5M26 6h6M25 7h7M24 8h8M23 9h9M22 10h10M21 11h11M20 12h12M19 13h13M18 14h14M17 15h15M16 16h16M15 17h17M14 18h18M13 19h19M12 20h20M11 21h21M10 22h22M9 23h23M8 24h24M7 25h25M6 26h26M5 27h27M4 28h28M3 29h29M2 30h30M1 31h31\" />";
    string constant internal GRADIENT_PINK = "<path stroke=\"#ffaec9\" d=\"M0 0h32M0 1h32M0 2h32M0 3h32M0 4h32M0 5h32M0 6h32M0 7h32\" /><path stroke=\"#fcacc7\" d=\"M0 8h32M0 9h32M0 10h32M0 11h32\" /><path stroke=\"#faaac5\" d=\"M0 12h32M0 13h32M0 14h32M0 15h32\" /><path stroke=\"#f2a5bf\" d=\"M0 16h32M0 17h32M0 18h32M0 19h32\" /><path stroke=\"#eba0b9\" d=\"M0 20h32M0 21h32M0 22h32M0 23h32\" /><path stroke=\"#e39bb3\" d=\"M0 24h32M0 25h32M0 26h32M0 27h32\" /><path stroke=\"#d692a9\" d=\"M0 28h32M0 29h32M0 30h32M0 31h32\" />";
    string constant internal GRADIENT_BLUE = "<path stroke=\"#a5edff\" d=\"M0 0h32M0 1h32M0 2h32M0 3h32\" /><path stroke=\"#9fe4f5\" d=\"M0 4h32M0 5h32M0 6h32M0 7h32\" /><path stroke=\"#9added\" d=\"M0 8h32M0 9h32M0 10h32M0 11h32\" /><path stroke=\"#97d8e8\" d=\"M0 12h32M0 13h32M0 14h32M0 15h32\" /><path stroke=\"#94d3e3\" d=\"M0 16h32M0 17h32M0 18h32M0 19h32\" /><path stroke=\"#8fccdb\" d=\"M0 20h32M0 21h32M0 22h32M0 23h32\" /><path stroke=\"#8cc7d6\" d=\"M0 24h32M0 25h32M0 26h32M0 27h32\" /><path stroke=\"#87c0cf\" d=\"M0 28h32M0 29h32M0 30h32M0 31h32\" />";
    string constant internal SPIRAL_SUFFIX = "\" d=\"M1 1h31M1 2h1M31 2h1M1 3h1M31 3h1M1 4h1M4 4h25M31 4h1M1 5h1M4 5h1M28 5h1M31 5h1M1 6h1M4 6h1M28 6h1M31 6h1M1 7h1M4 7h1M7 7h19M28 7h1M31 7h1M1 8h1M4 8h1M7 8h1M25 8h1M28 8h1M31 8h1M1 9h1M4 9h1M7 9h1M25 9h1M28 9h1M31 9h1M1 10h1M4 10h1M7 10h1M10 10h13M25 10h1M28 10h1M31 10h1M1 11h1M4 11h1M7 11h1M10 11h1M22 11h1M25 11h1M28 11h1M31 11h1M1 12h1M4 12h1M7 12h1M10 12h1M22 12h1M25 12h1M28 12h1M31 12h1M1 13h1M4 13h1M7 13h1M10 13h1M13 13h7M22 13h1M25 13h1M28 13h1M31 13h1M1 14h1M4 14h1M7 14h1M10 14h1M13 14h1M19 14h1M22 14h1M25 14h1M28 14h1M31 14h1M1 15h1M4 15h1M7 15h1M10 15h1M13 15h1M19 15h1M22 15h1M25 15h1M28 15h1M31 15h1M1 16h1M4 16h1M7 16h1M10 16h1M13 16h1M16 16h1M19 16h1M22 16h1M25 16h1M28 16h1M31 16h1M1 17h1M4 17h1M7 17h1M10 17h1M13 17h1M16 17h1M19 17h1M22 17h1M25 17h1M28 17h1M31 17h1M1 18h1M4 18h1M7 18h1M10 18h1M13 18h4M19 18h1M22 18h1M25 18h1M28 18h1M31 18h1M1 19h1M4 19h1M7 19h1M10 19h1M19 19h1M22 19h1M25 19h1M28 19h1M31 19h1M1 20h1M4 20h1M7 20h1M10 20h1M19 20h1M22 20h1M25 20h1M28 20h1M31 20h1M1 21h1M4 21h1M7 21h1M10 21h10M22 21h1M25 21h1M28 21h1M31 21h1M1 22h1M4 22h1M7 22h1M22 22h1M25 22h1M28 22h1M31 22h1M1 23h1M4 23h1M7 23h1M22 23h1M25 23h1M28 23h1M31 23h1M1 24h1M4 24h1M7 24h16M25 24h1M28 24h1M31 24h1M1 25h1M4 25h1M25 25h1M28 25h1M31 25h1M1 26h1M4 26h1M25 26h1M28 26h1M31 26h1M1 27h1M4 27h22M28 27h1M31 27h1M1 28h1M28 28h1M31 28h1M1 29h1M28 29h1M31 29h1M1 30h28M31 30h1M31 31h1\" />";
    string constant internal SPIRAL_GRAY = "ff8f91";
    string constant internal SPIRAL_RED = "ff8f91";
    string constant internal SPIRAL_VIOLET ="ebd6ff";
    string constant internal SPIRAL_GREEN = "e0ebe0";
    string constant internal POLKADOT_BLUE = "<path stroke=\"#99d9ea\" d=\"M1 0h2M8 0h2M15 0h2M22 0h2M29 0h2M0 1h1M3 1h1M7 1h1M10 1h1M14 1h1M17 1h1M21 1h1M24 1h1M28 1h1M31 1h1M0 2h1M3 2h1M7 2h1M10 2h1M14 2h1M17 2h1M21 2h1M24 2h1M28 2h1M31 2h1M1 3h2M8 3h2M15 3h2M22 3h2M29 3h2M3 7h2M10 7h2M17 7h2M24 7h2M31 7h1M2 8h1M5 8h1M9 8h1M12 8h1M16 8h1M19 8h1M23 8h1M26 8h1M30 8h1M2 9h1M5 9h1M9 9h1M12 9h1M16 9h1M19 9h1M23 9h1M26 9h1M30 9h1M3 10h2M10 10h2M17 10h2M24 10h2M31 10h1M5 14h2M12 14h2M19 14h2M26 14h2M0 15h1M4 15h1M7 15h1M11 15h1M14 15h1M18 15h1M21 15h1M25 15h1M28 15h1M0 16h1M4 16h1M7 16h1M11 16h1M14 16h1M18 16h1M21 16h1M25 16h1M28 16h1M5 17h2M12 17h2M19 17h2M26 17h2M0 21h2M7 21h2M14 21h2M21 21h2M28 21h2M2 22h1M6 22h1M9 22h1M13 22h1M16 22h1M20 22h1M23 22h1M27 22h1M30 22h1M2 23h1M6 23h1M9 23h1M13 23h1M16 23h1M20 23h1M23 23h1M27 23h1M30 23h1M0 24h2M7 24h2M14 24h2M21 24h2M28 24h2M2 28h2M9 28h2M16 28h2M23 28h2M30 28h2M1 29h1M4 29h1M8 29h1M11 29h1M15 29h1M18 29h1M22 29h1M25 29h1M29 29h1M1 30h1M4 30h1M8 30h1M11 30h1M15 30h1M18 30h1M22 30h1M25 30h1M29 30h1M2 31h2M9 31h2M16 31h2M23 31h2M30 31h2\" /><path stroke=\"#8ec9d9\" d=\"M1 1h2M8 1h2M15 1h2M22 1h2M29 1h2M1 2h2M8 2h2M15 2h2M22 2h2M29 2h2M3 8h2M10 8h2M17 8h2M24 8h2M31 8h1M3 9h2M10 9h2M17 9h2M24 9h2M31 9h1M5 15h2M12 15h2M19 15h2M26 15h2M5 16h2M12 16h2M19 16h2M26 16h2M0 22h2M7 22h2M14 22h2M21 22h2M28 22h2M0 23h2M7 23h2M14 23h2M21 23h2M28 23h2M2 29h2M9 29h2M16 29h2M23 29h2M30 29h2M2 30h2M9 30h2M16 30h2M23 30h2M30 30h2\" />";
    string constant internal GALAXY = "<path stroke=\"#7f7f7f\" d=\"M0 0h7M0 1h6M0 2h3M22 2h3M29 2h1M0 3h2M12 3h1M19 3h7M28 3h4M0 4h1M12 4h1M16 4h10M28 4h4M0 5h1M11 5h3M17 5h15M11 6h3M19 6h13M9 7h5M15 7h1M21 7h9M7 8h7M15 8h3M21 8h10M9 9h4M22 9h8M6 10h1M11 10h2M18 10h1M23 10h4M11 11h1M18 11h2M24 11h3M6 12h2M18 12h2M24 12h3M0 13h1M6 13h1M18 13h2M0 14h1M5 14h2M8 14h1M17 14h4M24 14h1M0 15h2M3 15h3M9 15h2M15 15h8M25 15h1M0 16h2M5 16h1M13 16h13M28 16h3M0 17h2M15 17h9M27 17h4M0 18h3M17 18h4M24 18h7M0 19h7M18 19h3M26 19h6M0 20h9M12 20h2M18 20h3M28 20h3M0 21h7M12 21h2M18 21h2M29 21h1M0 22h3M11 22h4M18 22h1M29 22h1M0 23h2M10 23h6M0 24h2M5 24h2M8 24h13M30 24h1M0 25h2M6 25h1M8 25h12M0 26h1M10 26h6M0 27h1M11 27h4M12 28h2M30 28h2M12 29h2M24 29h2M30 29h2M12 30h1M25 30h2M29 30h3M29 31h3\" /><path stroke=\"#c3c3c3\" d=\"M19 0h13M22 1h9M5 2h1M25 2h4M5 3h2M26 3h2M1 4h10M26 4h2M2 5h8M0 6h1M5 6h2M0 7h2M5 7h1M14 7h1M0 8h2M14 8h1M0 9h3M13 9h3M31 9h1M0 10h6M13 10h3M31 10h1M0 11h8M12 11h5M31 11h1M0 12h5M9 12h9M28 12h4M1 13h2M7 13h1M10 13h8M24 13h8M1 14h1M7 14h1M12 14h5M25 14h7M6 15h3M13 15h2M28 15h4M6 16h3M31 16h1M6 17h3M14 17h1M31 17h1M3 18h9M14 18h1M21 18h3M31 18h1M7 19h7M21 19h3M9 20h3M21 20h3M27 20h1M7 21h2M20 21h6M27 21h2M6 22h3M17 22h1M19 22h10M6 23h3M19 23h11M7 24h1M21 24h3M26 24h4M7 25h1M21 25h11M1 26h1M20 26h12M1 27h2M22 27h10M0 28h4M18 28h1M22 28h1M26 28h4M0 29h9M18 29h2M26 29h4M0 30h8M17 30h4M27 30h2M0 31h4M14 31h10M27 31h2\" />";
    string constant internal CONFETTI = "<path stroke=\"#3f48cc\" d=\"M0 0h1M0 1h2M0 2h3M0 3h3M0 4h3M0 5h3M0 6h3M0 7h3M0 8h3M0 9h3M0 10h3M0 11h3M0 12h3M0 13h3M0 14h3M0 15h3\" /><path stroke=\"#7092be\" d=\"M20 1h1M20 2h3M20 3h5M20 4h7M20 5h9M20 6h11M20 7h12M20 8h12M20 9h12M20 10h12M20 11h12M20 12h12M20 13h12M20 14h12M20 15h12\" /><path stroke=\"#fff200\" d=\"M8 2h1M8 3h2M8 4h3M8 5h4M8 6h5M8 7h5M9 8h4M10 9h3M11 10h2M12 11h1M8 19h5M8 20h17M8 21h18M8 22h19\" /><path stroke=\"#ff7f27\" d=\"M3 3h1M3 4h2M3 5h3M3 6h4M3 7h5M3 8h6M3 9h7M3 10h8M3 11h9M3 12h10M3 13h11M3 14h12M3 15h13M3 16h14M3 17h15M3 18h16\" /><path stroke=\"#22b14c\" d=\"M13 4h1M13 5h2M13 6h4M13 7h5M13 8h6M13 9h7M13 10h7M13 11h7M13 12h7M14 13h6M15 14h5M16 15h4M17 16h12M18 17h12M19 18h12M13 19h19\" /><path stroke=\"#ffaec9\" d=\"M0 19h1M0 20h2M0 21h3M0 22h4M0 23h4M0 24h5M0 25h6M0 26h7M0 27h8M0 28h8M0 29h9M0 30h10\" /><path stroke=\"#ed1c24\" d=\"M4 19h4M4 20h4M4 21h4M4 22h4M4 23h12M5 24h13M6 25h14M7 26h15M8 27h14M8 28h14M9 29h13\" /><path stroke=\"#7f7f7f\" d=\"M16 23h7M18 24h6M20 25h2M23 25h2M25 26h1\" /><path stroke=\"#b97a57\" d=\"M22 25h1M22 26h3M22 27h5M22 28h7M22 29h9M22 30h10M22 31h10\" />";
    
    function constructBackground(uint256 seed) internal pure returns (string memory) {
        uint40 _seed = uint40(seed >> 8*4);
        string memory color;

        if (_seed >= 206) {
            color = NONE;
        } else if (_seed >= 190) {
            color = GRAY;
        } else if (_seed >= 174) {
            color = ORANGE;
        } else if (_seed >= 158) {
            color = GREEN;
        } else if (_seed >= 142) {
            color = BLUE;
        } else if (_seed >= 126) {
            color = RED;
        } else if (_seed >= 110) {
            color = SKYBLUE;
        } else if (_seed >= 94) {
            color = VIOLET;
        } else if (_seed >= 78) {
            return HALF_YELLOW;
        } else if (_seed >= 62) {
            return HALF_PINK;
        } else if (_seed >= 46) {
            return HALF_VIOLET;
        } else if (_seed >= 32) {
            return GRADIENT_PINK;
        } else if (_seed >= 22) {
            return GRADIENT_BLUE;
        } else if (_seed >= 12) {
            return string.concat(
                PREFIX,
                NONE,
                SUFFIX,
                PREFIX,
                SPIRAL_GRAY,
                SPIRAL_SUFFIX
            );
        } else if (_seed >= 10) {
            return string.concat(
                PREFIX,
                NONE,
                SUFFIX,
                PREFIX,
                SPIRAL_RED,
                SPIRAL_SUFFIX
            );
        } else if (_seed >= 8) {
            return string.concat(
                PREFIX,
                NONE,
                SUFFIX,
                PREFIX,
                SPIRAL_VIOLET,
                SPIRAL_SUFFIX
            );
        } else if (_seed >= 6) {
            return string.concat(
                PREFIX,
                NONE,
                SUFFIX,
                PREFIX,
                SPIRAL_GREEN,
                SPIRAL_SUFFIX
            );
        } else if (_seed >= 4) {
            return string.concat(
                PREFIX,
                NONE,
                SUFFIX,
                POLKADOT_BLUE
            );
        } else if (_seed >= 2) {
            return string.concat(
                PREFIX,
                NONE,
                SUFFIX,
                GALAXY
            );
        } else {
            return string.concat(
                PREFIX,
                NONE,
                SUFFIX,
                CONFETTI
            );
        }

        return string.concat(
            PREFIX,
            color,
            SUFFIX
        );
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

interface IBCeeRenderer {
    function constructImage(uint256 seed) external pure returns (string memory);
}