// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

//
//                               ..:-=====--:.
//                          .-*#@@@@@@@@@@@@@@@@#+-.
//                       -*%@@@@@@@@@@@@@@@@@@@@@@@@%+:
//                     [email protected]@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@#-
//                   [email protected]@@%##*******#########%%%@@@@@@@@@@%=
//                 [email protected]@@@@@@@@%#***++++========-==*#%%@@@@@@#.
//                *@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@:
//               *@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@:
//              [email protected]@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@%@@@@@@@@@@@@.
//             [email protected]@@@@@@@@@@@@@@@@@@@@. [email protected]@@@@@*:    :[email protected]@@@@@@@@#
//             *@@@@@@@@@@@@@@@@@@@@.   :@@@@=  .+#+: [email protected]@@@@@@@@:
//             %@@@@@@@@@@@@@@@@@@@:  :  [email protected]@@   %@@@@  [email protected]@@@@@@@+
//             @@@@@@@@@@@@@@@@@@@:  [email protected]:  [email protected]@-  [email protected]@@#  [email protected]@@@@@@@%
//            [email protected]@@@@@@@@@@@@@@@@@=  [email protected]@@   [email protected]@-   ..  [email protected]@@@@@@@@#
//             %@@@@@@@@@@@@@@@@#---%@@@#---%@@%+-:-+#@@@@@@@@@@*
//             *@@@@@@@@@@@@@@@@@@@@@@@%#@%#@%%@%%@@@@@@@@@@@@@@-
//             [email protected]@@@@@@@@@@@@@@@@@@@@@@**%-+#*#@#%@@@@@@@@@@@@@%
//              [email protected]@@@@@@@@@@@@@@@@@@@@@%%@@@@@@@@@@@@@@@@@@@@@@:
//               *@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@-
//                [email protected]@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@=
//                 [email protected]@@@@@@@@%#**++=====-=====-====++#%%@@@#.
//                  .*@@@@%#*******###########%%%%%%@@@@@#=
//                    [email protected]@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@#=
//                       :*%@@@@@@@@@@@@@@@@@@@@@@@@%+.
//                          :=*#@@@@@@@@@@@@@@@%#+:
//                                :--===+==--:
//
// RIW & Pellar 2022

contract AOClaim {
  enum STATUS {
    UNAVAILABLE,
    MINTABLE,
    MINTED
  }

  mapping(uint16 => STATUS) public tokens;

  constructor() {
    tokens[4859] = STATUS.MINTABLE;
    tokens[5491] = STATUS.MINTABLE;
    tokens[5774] = STATUS.MINTABLE;
    tokens[1173] = STATUS.MINTABLE;
    tokens[3548] = STATUS.MINTABLE;
    tokens[4805] = STATUS.MINTABLE;
    tokens[3164] = STATUS.MINTABLE;
    tokens[2653] = STATUS.MINTABLE;
    tokens[3355] = STATUS.MINTABLE;
    tokens[1688] = STATUS.MINTABLE;
    tokens[2307] = STATUS.MINTABLE;
  }

  function claim(uint16 _id) external {
    require(tokens[_id] == STATUS.MINTABLE, "Not available");
    require(IAOToken(0x05844e9aE606f9867ae2047c93cAc370d54Ab2E1).ownerOf(_id) == msg.sender, "Not allowed");

    tokens[_id] = STATUS.MINTED;
  }

  function isClaimed(uint16 _id) public view returns (bool) {
    return tokens[_id] == STATUS.MINTED;
  }
}

interface IAOToken {
  function ownerOf(uint256 tokenId) external view returns (address owner);
}