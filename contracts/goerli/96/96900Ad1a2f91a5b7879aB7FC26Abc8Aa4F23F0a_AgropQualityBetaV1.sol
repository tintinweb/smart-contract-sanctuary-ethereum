// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

import "./interfaces/IAgropQuality.sol";
import "./interfaces/IAgrop.sol";

contract AgropQualityBetaV1 is IAgrop, IAgropQuality {
    /// @dev
    /// constructor
    constructor() {}

    // @dev
    /// validate crop options input
    function validateCropOptionsInput(AgropCropOptions memory _crop)
        external
        pure
        returns (bool)
    {
        // _crop.name,_crop.description,_crop.soil, _crop.climate,_crop.season,_crop.daytime, and _crop.store
        // keccak256(bytes(_crop.price)) == keccak256(bytes("")) ||
        bool stringinput = keccak256(bytes(_crop.name)) ==
            keccak256(bytes("")) ||
            keccak256(bytes(_crop.description)) == keccak256(bytes("")) ||
            keccak256(bytes(_crop.soil)) == keccak256(bytes("")) ||
            keccak256(bytes(_crop.season)) == keccak256(bytes("")) ||
            keccak256(bytes(_crop.daytime)) == keccak256(bytes("")) ||
            keccak256(bytes(_crop.store)) == keccak256(bytes(""));

        // _crop.thumbnails,_crop.videos,_crop.tools,_crop.tools
        // bool stringarrayinput = false;
        bool stringarrayinput = _crop.thumbnails.length == 0 ||
            _crop.videos.length == 0 ||
            _crop.tools.length == 0 ||
            _crop.climate.length == 0;

        // if required string input not submitted then revert.
        if (stringinput) {
            return false;
        }

        // if required string[] input not submitted then revert.
        if (stringarrayinput) {
            return false;
        }

        return true;
    }

    // @dev
    /// validate crop options input
    function calculateQuality(CropOptionsForQuality memory _crop)
        external
        pure
        returns (uint256)
    {
        uint256 qualitypercent = 0;

        // calculate quality
        // _crop.soil, _crop.climate,_crop.tools,_crop.season,_crop.daytime, and _crop.store

        // pepper
        if (keccak256(bytes(_crop.family)) == keccak256(bytes("pepper"))) {
            // soil
            bool soil = keccak256(bytes(_crop.soil)) ==
                keccak256(bytes("sandy")) ||
                keccak256(bytes(_crop.soil)) == keccak256(bytes("loamy"));

            // climate
            uint256 from = _crop.climate[0];
            uint256 to = _crop.climate[1];
            bool climate = from >= 16 && to <= 21;

            // tools

            // season
            bool season = keccak256(bytes(_crop.season)) ==
                keccak256(bytes("raining"));

            // daytime
            bool daytime = keccak256(bytes(_crop.daytime)) ==
                keccak256(bytes("morning"));

            // store
            bool store = keccak256(bytes(_crop.store)) ==
                keccak256(bytes("refrigerator"));

            if (soil) qualitypercent += 20;
            if (climate) qualitypercent += 20;
            if (season) qualitypercent += 20;
            if (daytime) qualitypercent += 20;
            if (store) qualitypercent += 20;
        }

        // vegetables
        if (keccak256(bytes(_crop.family)) == keccak256(bytes("vegetables"))) {
            // soil
            bool soil = keccak256(bytes(_crop.soil)) ==
                keccak256(bytes("loamy"));

            // climate
            uint256 from = _crop.climate[0];
            uint256 to = _crop.climate[1];
            bool climate = from >= 0 && to <= 21;

            // tools

            // season
            bool season = keccak256(bytes(_crop.season)) ==
                keccak256(bytes("raining"));

            // daytime
            bool daytime = keccak256(bytes(_crop.daytime)) ==
                keccak256(bytes("morning"));

            // store
            bool store = keccak256(bytes(_crop.store)) ==
                keccak256(bytes("refrigerator"));

            if (soil) qualitypercent += 20;
            if (climate) qualitypercent += 20;
            if (season) qualitypercent += 20;
            if (daytime) qualitypercent += 20;
            if (store) qualitypercent += 20;
        }

        // fruits
        if (keccak256(bytes(_crop.family)) == keccak256(bytes("fruits"))) {
            // soil
            bool soil = keccak256(bytes(_crop.soil)) ==
                keccak256(bytes("loamy"));

            // climate
            uint256 from = _crop.climate[0];
            uint256 to = _crop.climate[1];
            bool climate = from >= 0 && to <= 21;

            // tools

            // season
            bool season = keccak256(bytes(_crop.season)) ==
                keccak256(bytes("raining")) ||
                keccak256(bytes(_crop.season)) == keccak256(bytes("dry"));

            // daytime
            bool daytime = keccak256(bytes(_crop.daytime)) ==
                keccak256(bytes("night"));

            // store
            bool store = keccak256(bytes(_crop.store)) ==
                keccak256(bytes("refrigerator"));

            if (soil) qualitypercent += 20;
            if (climate) qualitypercent += 20;
            if (season) qualitypercent += 20;
            if (daytime) qualitypercent += 20;
            if (store) qualitypercent += 20;
        }

        // maize
        if (keccak256(bytes(_crop.family)) == keccak256(bytes("maize"))) {
            // soil
            bool soil = keccak256(bytes(_crop.soil)) ==
                keccak256(bytes("sandy")) ||
                keccak256(bytes(_crop.soil)) == keccak256(bytes("loamy"));

            // climate
            uint256 from = _crop.climate[0];
            uint256 to = _crop.climate[1];
            bool climate = from >= 21 && to <= 27;

            // tools

            // season
            bool season = keccak256(bytes(_crop.season)) ==
                keccak256(bytes("raining"));

            // daytime
            bool daytime = keccak256(bytes(_crop.daytime)) ==
                keccak256(bytes("morning"));

            // store
            bool store = keccak256(bytes(_crop.store)) ==
                keccak256(bytes("barn"));

            if (soil) qualitypercent += 20;
            if (climate) qualitypercent += 20;
            if (season) qualitypercent += 20;
            if (daytime) qualitypercent += 20;
            if (store) qualitypercent += 20;
        }

        // cassava
        if (keccak256(bytes(_crop.family)) == keccak256(bytes("cassava"))) {
            qualitypercent += 100;
        }

        // cocoa
        if (keccak256(bytes(_crop.family)) == keccak256(bytes("cocoa"))) {
            qualitypercent += 100;
        }

        return qualitypercent;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

import "./IAgrop.sol";

interface IAgropQuality {
    // @dev
    /// validate crop options input
    function validateCropOptionsInput(IAgrop.AgropCropOptions memory _crop)
        external
        pure
        returns (bool);

    // @dev
    /// validate crop options input
    function calculateQuality(IAgrop.CropOptionsForQuality memory _crop)
        external
        pure
        returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

interface IAgrop {
    struct AgropCropOptions {
        string name;
        string family;
        string description;
        uint256 price;
        string[] thumbnails;
        string[] videos;
        string soil;
        uint256[] climate;
        string[] tools;
        string season;
        string daytime;
        string store;
        // quality percent
        uint256 quality;
    }

    struct CropOptionsForQuality {
        string family;
        string soil;
        uint256[] climate;
        string[] tools;
        string season;
        string daytime;
        string store;
    }
}