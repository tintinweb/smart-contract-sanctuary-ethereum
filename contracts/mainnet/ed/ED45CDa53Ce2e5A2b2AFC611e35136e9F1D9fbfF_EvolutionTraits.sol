// SPDX-License-Identifier: MIT
/* solhint-disable quotes */
pragma solidity ^0.8.7;

import "@openzeppelin/contracts/access/Ownable.sol";

contract EvolutionTraits is Ownable {
    struct TraitData {
        string svgImageTag;
        string name;
    }

    FreakChip public freakChip;
    RobotChip public robotChip;
    SkeleChip public skeleChip;
    AlienChip public alienChip;
    DruidChip public druidChip;
    string[] public baseNames = ["Freak", "Robot", "Druid", "Underworld", "Alien"];
    string[] public traitTypeNames = ["Character", "Earrings", "Eyes", "Hat", "Mouth", "Neck", "Nose", "Whisker"];
    // character => traitType => traits
    mapping(uint8 => mapping(uint8 => TraitData[10])) public traitDataByCharacter;
    string public evolvedIncubatorImage;

    constructor() {
        freakChip = new FreakChip();
        robotChip = new RobotChip();
        skeleChip = new SkeleChip();
        alienChip = new AlienChip();
        druidChip = new DruidChip();
    }

    function getDNAChipSVG(uint256 base) external view returns (string memory) {
        if (base == 0) {
            return freakChip.getChipImageTag();
        }
        if (base == 1) {
            return robotChip.getChipImageTag();
        }
        if (base == 2) {
            return druidChip.getChipImageTag();
        }
        if (base == 3) {
            return skeleChip.getChipImageTag();
        }
        if (base == 4) {
            return alienChip.getChipImageTag();
        }
        revert("invalid base");
    }

    function getEvolutionPodImageTag(uint256 base) external view returns (string memory) {
        if (base == 0) {
            return freakChip.getEvolutionPodImageTag();
        }
        if (base == 1) {
            return robotChip.getEvolutionPodImageTag();
        }
        if (base == 2) {
            return druidChip.getEvolutionPodImageTag();
        }
        if (base == 3) {
            return skeleChip.getEvolutionPodImageTag();
        }
        if (base == 4) {
            return alienChip.getEvolutionPodImageTag();
        }
        revert("invalid base");
    }

    function getTraitsImageTags(uint8[8] memory traits) external view returns (string memory) {
        uint8 base = traits[0];

        string memory result;
        for (uint8 index = 0; index < traits.length; index++) {
            uint8 traitValue = traits[index];
            result = string(abi.encodePacked(result, traitDataByCharacter[base][index][traitValue].svgImageTag));
        }

        return result;
    }

    function getTraitsImageTagsByOrder(uint8[8] memory traits, uint8[8] memory traitsOrder)
        external
        view
        returns (string memory)
    {
        uint8 base = traits[0];
        string memory result;

        for (uint256 index = 0; index < traitsOrder.length; index++) {
            uint8 currentTrait = traitsOrder[index];
            uint8 traitValue = traits[currentTrait];
            result = string(abi.encodePacked(result, traitDataByCharacter[base][currentTrait][traitValue].svgImageTag));
        }

        return result;
    }

    function getMetadata(uint8[8] memory traits) external view returns (string memory) {
        string memory metadataString;
        uint8 base = traits[0];
        for (uint8 index = 0; index < traits.length - 1; index++) {
            uint8 traitValue = traits[index];

            metadataString = string(
                abi.encodePacked(
                    metadataString,
                    '{"trait_type": "',
                    traitTypeNames[index],
                    '","value":"',
                    traitDataByCharacter[base][index][traitValue].name,
                    '"}',
                    ","
                )
            );
        }
        metadataString = string(
            abi.encodePacked(
                metadataString,
                '{"trait_type": "',
                traitTypeNames[traits.length - 1],
                '","value":"',
                traitDataByCharacter[base][uint8(traits.length - 1)][traits[traits.length - 1]].name,
                '"}'
            )
        );

        return metadataString;
    }

    function setTraitTypeData(
        uint8 base,
        uint8 traitType,
        TraitData[] calldata traits
    ) external onlyOwner {
        for (uint256 index = 0; index < traits.length; index++) {
            traitDataByCharacter[base][traitType][index] = traits[index];
        }
    }

    function setEvolvedIncubatorImage(string calldata _evolvedIncubatorImage) external onlyOwner {
        evolvedIncubatorImage = _evolvedIncubatorImage;
    }

    function setTraitData(
        uint8 base,
        uint8 traitType,
        uint8 traitIndex,
        string calldata name,
        string calldata svgImageTag
    ) external onlyOwner {
        traitDataByCharacter[base][traitType][traitIndex] = TraitData({svgImageTag: svgImageTag, name: name});
    }

    function setFreakChipAddress(address freakChipAddress) external onlyOwner {
        freakChip = FreakChip(freakChipAddress);
    }

    function setRobotChipAddress(address robotChipAddress) external onlyOwner {
        robotChip = RobotChip(robotChipAddress);
    }

    function setDruidChipAddress(address druidChipAddress) external onlyOwner {
        druidChip = DruidChip(druidChipAddress);
    }

    function setSkeleChipAddress(address skeleChipAddress) external onlyOwner {
        skeleChip = SkeleChip(skeleChipAddress);
    }

    function setAlienChipAddress(address alienChipAddress) external onlyOwner {
        alienChip = AlienChip(alienChipAddress);
    }
}

contract FreakChip {
    function getEvolutionPodImageTag() external pure returns (string memory) {
        return
            '<image x="0" y="0" width="125" height="125" image-rendering="pixelated" preserveAspectRatio="xMidYMid" xlink:href="data:image/png;base64,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" />';
    }

    function getChipImageTag() external pure returns (string memory) {
        return
            '<image x="10" y="20" width="100" height="100" image-rendering="pixelated" preserveAspectRatio="xMidYMid" xlink:href="data:image/png;base64,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" />';
    }
}

contract RobotChip {
    function getEvolutionPodImageTag() external pure returns (string memory) {
        return
            '<image x="0" y="0" width="125" height="125" image-rendering="pixelated" preserveAspectRatio="xMidYMid" xlink:href="data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAAH0AAAB9CAMAAAC4XpwXAAAACXBIWXMAAAsSAAALEgHS3X78AAAAG3RFWHRTb2Z0d2FyZQBDZWxzeXMgU3R1ZGlvIFRvb2zBp+F8AAABm1BMVEUAAAAAMHwARrIGBgYXIyEaGhoeHh4fHhggICAgIyEhISEjICEjIyMkJCQnKi0oKCgpKSkpKisqKioqKyEqMiwrJyUrKDgsLCwuJycuLCowKSkyMjI1AJc4NUU6NTI7AKc9PT09QUY/QkdAQEBAQkRDQ0NISEhMTExNTU1PT09QVE9SRnxSUlJVU1RWU3dWVlZYWFhdXV1fSVdgYGBhX3VhYWFhZ25iWYFiYmJjYnplZWVlcHppanxrZYBtbW1vb290AAB0d5Z5d3h6enp7eop+f4x/g76Bf5SBgYGCgpOEhZ+EjK2FkJqGiKmGib2HiZ+Me8SNkbuOjZqQgr6TAAWUlq+WlpaZNTOZnMyanLKbODWcnJycn86cqLaeqrafn5+hpr+jNzqjpb6kp+Olp8mnq+WqsdKtr8mtsNWusNe4utS4xdS7vdK+wNq+wN6+zNrC0N/EwsPGyN7Gye/G1ePJAAfLzeDLzeHMzdzNzuHWKCvY2efb3Oni+v/kBgDq+//vBgD0BgD8CgD9BwD/AAT/AAj/CBD/CgD///8mxouaAAAJ/klEQVRo3sWYjV8bSRnH5xLfqC6986W+0HikEAGJJmuBClescUPvkpZeATEBQYVrIw2GVEivClvv6lHOP9tnXnZ2Znbekp4ff4UkbHbnO7/nmefZ2aLqkGp92aq+rcJEyO/E4enSRaZxkd8k0xlgeujlzuMklJ6X85rE7pe77pGNcOUoSm0hryD40I1s9TBKx0XWUSW6M6Z+cJXuXimYPhJcN7ZKD4eoOOPZoSd8BPq/W3Iy/Evcgx760z0mkHwX+tIdfJkulYN57YdD0K381hctSzcwFJ76XfIZpV8j4zDieLuELp3lBw/lNUD+FloMkn2Y6v2L3exJerbp2/RqhW4OpJ4e2lqDcWnq7nFIl8nMJQo9dN8XdeexQyIdIftC0tJDVwWYEqncWgS6cSkB/bWZrjtszZCRLgwmV9xrU+TDoeFWuvbi1uuWexNQ9YO76NXMgAb6KGw3PbMAtPTQDLe2bTddWQEaumUJZofKDU8XIIweuvZRHstcS7dGK6k4507GI9g6uqOJtj5vVd1wr1SrdPuNhtNH2lOKQF2fV81r8V8BPQwtdPtt1oduw0u7CCSy+aK37JV2P991PqnZvvGgm3eLmO61BzLtUHzoZil04zOT/L129zgCHfIeeuA1HfgromvGNT4waOi653c7PWWIa15jzfl0Ky1tL7o4dOtfLZs1d69DuluLhS6NK9NtTxP6ucj0HIOa6fKwWbr2MdEYB4WeQ5Ic8BrQa6M+skodldFz79joCvzjWq3215pwPHRGy0kXAuAYqPbxNobblpljI6mjv+OM+28JfBvo2zX7U7N17XMKfnfQhZEQgR+e/u30MMUPyUaqrHRxKIThQP8H0Ldr7tLU3XeHocuDIQo/jU/NeFcJSMvbEvlsYhGDx0Pi5XESdj6v0u0bdAKPqU4PDwm+PCzcTdd1TsThFwxP3Jc92WHVl641jhL4S+4e48ue/w+fWfWBga4vZTHsAr7stbHQ1Zyerm8jUOcUfkEk5d7P8zB05RIOZ1mnGdDhQ9fDECFb6VUt/CKlX4i59/6fS7He9XnXwg8Pec4vlNwfHrrqPtB3WhNdvRwbPyWhFpIef0pkyb2FnjfTdfA4pTL/n45RufFG72qf1z6BqZV2gekJHONHoue0dCec8Cn862Pf8sAP4b2qp1/EO/HOzs5avLbD6de//ffvj10blR4Qet5BF3r7muz9D7/7z0++Njb2Hcv9Lp8PQFl64Os9oa/Fd8H6DpkCpV/76Y8uv0m9G+j5PMFrveeHosvC9B/++AcH33t37LqdDrLkPRv5ssH72s5dyPrdhP6NX9/+xa9+/jOb9yrxXjXVu9a7hv5SMv6S0L87e3vx9u3fXBuFzivO5T2tuAux4wA+uJbUuwWuz7u3d6Xe+RQAf/06W3NaOkt6EEjL3rnqyiBxtngnaZYJjvHpj3+3ydJt2jbR86KGWPNliY+q2xbVsPTWA0FD5F2lV38JqjHBJ+EzUdVIz+Xwjzbv3t6raNOi5FS1p/IVp6cH3t5hnuvA+ZD84tfNRqNB2UHA6cr9JPUOqBEiT18RuSS/DvwPG6rglCAj1XuWbq+4YHISfujAKAjobMFuAt1M8Xp2bBRFWiPPBmLeZ4gaYP6GqkaapISM31/dNOqVrd4Zl3on00DBDNPmgxt35rceP96av3MH3h5v3ZHp90DU+c33jboZG/OOsVhiGBFwK5VKvV7XeN9cWBDocBrmnznp+ooTwZPEfLlM6CtNvMCbXEm5ra83FiZZtu5VYDeO+V70QOc94N4FOnhq1nGdqdZhFusL9LTyvcoiUaVyNmLkJycnRTrhI4CvrBB888bl+cGfPzuvXzYOGgeXB0B/APhHj/b29h4BvEIeoJ56ec9701fA/DHgNd6Bvr6wt/fsGczgUYnY96DnTHmX6SCgD7rdbo/EXquFBfh+79keTKDi7V0beYCenAh0hHq9426v1+11ms16k/4S1ZPOs7lA+d1Sac7Te17rHVNP4viE0PGAvS7RMX7vK+77nX6/s7zcaCzABP5SAvZc5a3yTuFxfLQRdPud3oDQLw+Oz48Pup1Os84EH/7Yx7PqD7D5B/CP4ish9f7+iN2G0I822kfUdI857x0PejPNejfV4PzyoH8wgKAz4dBj84sj551bB3oHZ7tD6BCDXm9xZlkMPfC7GQF+cfRVVy5z64N+knQSA1zNM8vL9dR+h4ZgGWuD6U+w7kbPezm1TsLeAc/9GQDjHrYILRfzqffBYAATYNQTqjbQvVZdTuudw3sDXGQQ8D6UIcZXKuQ2FyDMrxPDy91+gk1u3m1Put57Su+T2A4mcROYIewSwPGjb7C8jOh9qLtxpGwdfOl5h/ceazikBRHbnM76wtvQ9atufv4GgR8LezJ8GrBL+Aej82lHztABH84NR/8o1dbWFqF/pCjxrhzW0eecdGkINJeKep/LitLVo6PRpSFEOvWup88Y6Kurq/OgVay3oxu9z+HMl7T0QqHA7vaFApgflr6SinY64UD0Hn2fKpWmpt6dUkToW4IYHfAZvWHv8YoktJTqBMOFv6P3ikzj5GW8KIlGfp4EngSf0zN68/s37NOSJCO9WJwl8FmOH5dF6YUk7PDL6W0ujo/96QQ4y52rXCZd5EslTD8DffIJfmHMh3F8FV+9eMHpkUiPoojTGZHDx00i9Hke+flVTpe8P3/+wUM2CaBHFKfxDvijDQWuw04I9DTwJPKUjn3TX0x/+ByTE+9RlLAjhb6k0g2uJyYmErrcbeASTL/PBQf3P9hnvuMXtrwvFU8SugifILiJCXUCNPJxAdZ9IS7Mw0tCh5CfEeHI7+/v07mJedfQ4dqY0SXnClhOvNY79CDuPc05RN9Mx0Bq3hp2Mx3DCb1wdX51/+r8/tV9mnBKv3rhohPzbMWNTpfyHsfnvt6LJxvecE/6OaNjUXrEXxAv94hm/GhDzrlQYg48gRe1nTYVay+s5BPv+C+y2F9tyMYzq12Y18YR21f+EyulP6V68oR/SKTtdUJvh9AnbGf8Je8UXhR7HQGmjU+g6+p9Caf8FScXnfnn5sG+QIdKx5bpa+ocPseRmR5Ng/0Tjp4terV6yfoS8y6ZbrfxLOBgO56OZHokwpOlr5N6hyW3eJ53QofLBe/EP31NjsRLHB/RPs+7/rRUe17i5tsEzehSqp+0eShI3lP3kRD5FK7OYHbWQqfW28ll4+OC97Mzku8zbv0pXnVC8JEBLk9hVpQ0IWae0W/hlJCKSxOehgHf74sSHtng+kwkM4CBikuUTuG3CHxq3NZtihKe7W2mbXDjpCJGT+JO8eqdeEK8S9LVMc34yGncHhOC51ln+An53iw0y2Liepp3WhUeDcHH9LZw4JbGP5d4JcGj0Z1blJlCMXvONKn3/wHcT4BH/zc4xv8X6f7tKFYXIKAAAAAASUVORK5CYII=" />';
    }

    function getChipImageTag() external pure returns (string memory) {
        return
            '<image x="10" y="20" width="100" height="100" image-rendering="pixelated" preserveAspectRatio="xMidYMid" xlink:href="data:image/png;base64,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" />';
    }
}

contract SkeleChip {
    function getEvolutionPodImageTag() external pure returns (string memory) {
        return
            '<image x="0" y="0" width="125" height="125" image-rendering="pixelated" preserveAspectRatio="xMidYMid" xlink:href="data:image/png;base64,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" />';
    }

    function getChipImageTag() external pure returns (string memory) {
        return
            '<image x="10" y="20" width="100" height="100" image-rendering="pixelated" preserveAspectRatio="xMidYMid" xlink:href="data:image/png;base64,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" />';
    }
}

contract AlienChip {
    function getEvolutionPodImageTag() external pure returns (string memory) {
        return
            '<image x="0" y="0" width="125" height="125" image-rendering="pixelated" preserveAspectRatio="xMidYMid" xlink:href="data:image/png;base64,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"/>';
    }

    function getChipImageTag() external pure returns (string memory) {
        return
            '<image x="10" y="20" width="100" height="100" image-rendering="pixelated" preserveAspectRatio="xMidYMid" xlink:href="data:image/png;base64,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"/>';
    }
}

contract DruidChip {
    function getEvolutionPodImageTag() external pure returns (string memory) {
        return
            '<image x="0" y="0" width="125" height="125" image-rendering="pixelated" preserveAspectRatio="xMidYMid" xlink:href="data:image/png;base64,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"/>';
    }

    function getChipImageTag() external pure returns (string memory) {
        return
            '<image x="10" y="20" width="100" height="100" image-rendering="pixelated" preserveAspectRatio="xMidYMid" xlink:href="data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAAGQAAABkCAMAAABHPGVmAAAAAXNSR0IArs4c6QAAAIpQTFRFAAAAkZS3mJiYmjcnmp26nT0tn6G7pD8vqEEwrUMxra/As0Uzvb29wcHBw8PDysrK0j0k/73YAAAAAHVOAKRtAOydBYteCQkJEBAQFxcXG3M9Hh4eJY1NLCwsNjY2ODg4S0tLT09PUFBQWVlZXV1dX8WjX/98fn5+hoaGjIyMmJiYm5ub/8cA////MTUG2AAAABJ0Uk5TAAAAAAAAAAAAAAAAAAAAAAAAlXM9PwAAA11JREFUaN7tmo1WozAQhRv/V7Ra20VNx9ASbAxd3v/1diYJFGm3JqFyVu3tAask8+VOBggcR6OjjvqemnTE0i2xbpteELZHh4Ok/9RhIOxjHQKSfqDeEOannpDUR70gzF89IKmv4iGMBVqJgqRpmJUICAtUHCQNURyEBSsGkgYqAsIiFA5Jg8V+rhPGBrASYSTcytHJ0ckXd3K8dv2HTga5Mw5zjx9ktTLMumuQFeQwa+FBVvXDPJ8M8qQ12DOjx9PvF3DSBNl3oh/qwXSfiS9SwiwdoITZECX8fZx4een/vivAR6/Xg8zTRz+Ip49Pe9HJ+r2yvUd5TEwvyKkltd522stUc7myf+r58rlTyDbmBmSpB4BUHxfypG+6qj/V/f6pZ5MDODltul9fnG25OLu4dkeTJImGwGRy5zQudxgpx3SI3/HE5DW5ujw/D5xywO4wLp30LtlDfMwJllCvy6vEH0EjLOnTCtnxobWQuGngALwE4yrECGB6StAaKLYQereEJIoTDYhAv7xt3BoHIGCNvaUULi+vbTVZXKOIgkMqy9s7b0aJOTD98Gc9KeXvrtzfORgYl+Tbm3KDXaTGRHNKNzgX063imjo3JRAJG5pauPGDnNgsU/SWkddpV8QQ0lDMcGin9Ykf5EFholtFCnZ77aqkmSeKC0/mtXrwhDwqWzt1WXG9MdQRtZKtilOP3pAnpZo6xUGaKe3Wr9Cy+eYKTCv1FAB5nquag2Pl0gZy8fGL1JIstM8g7KDmz2GQ+UtG3ZQ5oSnphJN6E3jdzJuJr7LsZR4BybI8z5VTa8zO09pFVwqbYeNYiBB5/maldskeyrFZHwiOsbB62yV7iFplVXy6IBcYZSmWRb5LxbI+hHfRMAgYCFhIXlSWstgWuViKAtMlNk7AEwKcnCAFsDuOkXKyWK1mVTXDvdlwP1stbLpypGTcQrAOR94UShdkHBOxrIolQdIVfoxm9W6BFgubLmycYSfuzSAKjijjQHVT8KIAnJn3mQKXLjPxprp4Zk6nsEWEuazS5AJhMPE0YGE3oIrAj5kSclJfhiF0qWLvJ5gxw6LoNGQraNeYJRhFrIjM6LjZgWW6YC5qc8j9Evs/H3UIm24Tizuk+2LGHx2/lbb3NVF7iJiDo36W/gLdelGOlFP4LAAAAABJRU5ErkJggg=="/>';
    }
}

/* solhint-enable quotes */

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _transferOwnership(_msgSender());
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}