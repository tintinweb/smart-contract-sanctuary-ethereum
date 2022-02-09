// SPDX-License-Identifier: The Unlicense
pragma solidity ^0.8.9;

import "./interfaces/IShields.sol";
import "./interfaces/IEmblemWeaver.sol";
import "./interfaces/IFieldGenerator.sol";
import "./interfaces/IHardwareGenerator.sol";
import "./interfaces/IFrameGenerator.sol";
import "./interfaces/IShieldBadgeSVGs.sol";
import "./interfaces/IShieldsAPI.sol";

contract ShieldsAPI is IShieldsAPI {
    IShields public immutable shields;
    IEmblemWeaver public immutable emblemWeaver;
    IFieldGenerator public immutable fieldGenerator;
    IHardwareGenerator public immutable hardwareGenerator;
    IFrameGenerator public immutable frameGenerator;
    IShieldBadgeSVGs public immutable shieldBadgeSVGGenerator;

    constructor(IShields _shields) {
        shields = _shields;
        emblemWeaver = _shields.emblemWeaver();
        fieldGenerator = emblemWeaver.fieldGenerator();
        hardwareGenerator = emblemWeaver.hardwareGenerator();
        frameGenerator = emblemWeaver.frameGenerator();
        shieldBadgeSVGGenerator = emblemWeaver.shieldBadgeSVGGenerator();
    }

    // *** Shields *** //
    function getShield(uint256 shieldId)
        public
        view
        returns (IShields.Shield memory)
    {
        (
            uint16 field,
            uint16 hardware,
            uint16 frame,
            uint24 color1,
            uint24 color2,
            uint24 color3,
            uint24 color4,
            IShields.ShieldBadge shieldBadge
        ) = shields.shields(shieldId);
        return
            IShields.Shield(
                color1 != 0,
                field,
                hardware,
                frame,
                shieldBadge,
                [color1, color2, color3, color4]
            );
    }

    function getShieldSVG(uint256 shieldId)
        public
        view
        returns (string memory)
    {
        IShields.Shield memory shield = getShield(shieldId);
        if (!shield.built)
            return
                shieldBadgeSVGGenerator.generateShieldBadgeSVG(
                    shield.shieldBadge
                );
        else
            return
                getShieldSVG(
                    shield.field,
                    shield.colors,
                    shield.hardware,
                    shield.frame
                );
    }

    function getShieldSVG(
        uint16 field,
        uint24[4] memory colors,
        uint16 hardware,
        uint16 frame
    ) public view returns (string memory) {
        return
            _wrapSVG(
                string(
                    abi.encodePacked(
                        getFieldSVG(field, colors),
                        getHardwareSVG(hardware),
                        getFrameSVG(frame)
                    )
                )
            );
    }

    function isShieldBuilt(uint256 shieldId) public view returns (bool) {
        return getShield(shieldId).built;
    }

    // *** Fields *** //
    function getField(uint16 field, uint24[4] memory colors)
        public
        view
        returns (IFieldGenerator.FieldData memory)
    {
        return fieldGenerator.generateField(field, colors);
    }

    function getFieldTitle(uint16 field, uint24[4] memory colors)
        public
        view
        returns (string memory)
    {
        return fieldGenerator.generateField(field, colors).title;
    }

    function getFieldSVG(uint16 field, uint24[4] memory colors)
        public
        view
        returns (string memory)
    {
        return _wrapSVG(fieldGenerator.generateField(field, colors).svgString);
    }

    // *** Hardware *** //
    function getHardware(uint16 hardware)
        public
        view
        returns (IHardwareGenerator.HardwareData memory)
    {
        return hardwareGenerator.generateHardware(hardware);
    }

    function getHardwareTitle(uint16 hardware)
        public
        view
        returns (string memory)
    {
        return hardwareGenerator.generateHardware(hardware).title;
    }

    function getHardwareSVG(uint16 hardware)
        public
        view
        returns (string memory)
    {
        return _wrapSVG(hardwareGenerator.generateHardware(hardware).svgString);
    }

    // *** Frames *** //
    function getFrame(uint16 frame)
        public
        view
        returns (IFrameGenerator.FrameData memory)
    {
        return frameGenerator.generateFrame(frame);
    }

    function getFrameTitle(uint16 frame) public view returns (string memory) {
        return frameGenerator.generateFrame(frame).title;
    }

    function getFrameSVG(uint16 frame) public view returns (string memory) {
        return _wrapSVG(frameGenerator.generateFrame(frame).svgString);
    }

    // *** SVG *** //
    function _wrapSVG(string memory svg) private pure returns (string memory) {
        return
            string(
                abi.encodePacked(
                    '<svg xmlns="http://www.w3.org/2000/svg" xmlns:xlink="http://www.w3.org/1999/xlink" viewBox="0 0 220 264">',
                    svg,
                    "</svg>"
                )
            );
    }
}

// SPDX-License-Identifier: The Unlicense
pragma solidity ^0.8.9;

import "./IShields.sol";
import "./IFieldGenerator.sol";
import "./IHardwareGenerator.sol";
import "./IFrameGenerator.sol";

interface IShieldsAPI {
    function getShield(uint256 shieldId)
        external
        view
        returns (IShields.Shield memory);

    function getShieldSVG(uint256 shieldId)
        external
        view
        returns (string memory);

    function getShieldSVG(
        uint16 field,
        uint24[4] memory colors,
        uint16 hardware,
        uint16 frame
    ) external view returns (string memory);

    function isShieldBuilt(uint256 shieldId) external view returns (bool);

    function getField(uint16 field, uint24[4] memory colors)
        external
        view
        returns (IFieldGenerator.FieldData memory);

    function getFieldTitle(uint16 field, uint24[4] memory colors)
        external
        view
        returns (string memory);

    function getFieldSVG(uint16 field, uint24[4] memory colors)
        external
        view
        returns (string memory);

    function getHardware(uint16 hardware)
        external
        view
        returns (IHardwareGenerator.HardwareData memory);

    function getHardwareTitle(uint16 hardware)
        external
        view
        returns (string memory);

    function getHardwareSVG(uint16 hardware)
        external
        view
        returns (string memory);

    function getFrame(uint16 frame)
        external
        view
        returns (IFrameGenerator.FrameData memory);

    function getFrameTitle(uint16 frame) external view returns (string memory);

    function getFrameSVG(uint16 frame) external view returns (string memory);
}

// SPDX-License-Identifier: The Unlicense
pragma solidity ^0.8.9;

import "./IShields.sol";

interface IShieldBadgeSVGs {
    function generateShieldBadgeSVG(IShields.ShieldBadge shieldBadge)
        external
        view
        returns (string memory);
}

// SPDX-License-Identifier: The Unlicense
pragma solidity ^0.8.9;

interface IFrameGenerator {
    struct FrameData {
        string title;
        uint256 fee;
        string svgString;
    }

    function generateFrame(uint16 Frame)
        external
        view
        returns (FrameData memory);
}

// SPDX-License-Identifier: The Unlicense
pragma solidity ^0.8.9;

interface IHardwareGenerator {
    enum HardwareCategories {
        STANDARD,
        SPECIAL
    }
    struct HardwareData {
        string title;
        HardwareCategories hardwareType;
        string svgString;
    }

    function generateHardware(uint16 hardware)
        external
        view
        returns (HardwareData memory);
}

// SPDX-License-Identifier: The Unlicense
pragma solidity ^0.8.9;

interface IFieldGenerator {
    enum FieldCategories {
        MYTHIC,
        HERALDIC
    }
    struct FieldData {
        string title;
        FieldCategories fieldType;
        string svgString;
    }

    function generateField(uint16 field, uint24[4] memory colors)
        external
        view
        returns (FieldData memory);
}

// SPDX-License-Identifier: The Unlicense
pragma solidity ^0.8.9;

import "./IShields.sol";
import "./IFrameGenerator.sol";
import "./IFieldGenerator.sol";
import "./IHardwareGenerator.sol";
import "./IShieldBadgeSVGs.sol";

interface IEmblemWeaver {
    function fieldGenerator() external returns (IFieldGenerator);

    function hardwareGenerator() external returns (IHardwareGenerator);

    function frameGenerator() external returns (IFrameGenerator);

    function shieldBadgeSVGGenerator() external returns (IShieldBadgeSVGs);

    function generateShieldURI(IShields.Shield memory shield)
        external
        view
        returns (string memory);

    function generateShieldBadgeURI(IShields.ShieldBadge shieldBadge)
        external
        view
        returns (string memory);
}

// SPDX-License-Identifier: The Unlicense
pragma solidity ^0.8.9;

import "./IEmblemWeaver.sol";

interface IShields {
    enum ShieldBadge {
        MAKER,
        STANDARD
    }

    struct Shield {
        bool built;
        uint16 field;
        uint16 hardware;
        uint16 frame;
        ShieldBadge shieldBadge;
        uint24[4] colors;
    }

    function emblemWeaver() external view returns (IEmblemWeaver);

    function shields(uint256 tokenId)
        external
        view
        returns (
            uint16 field,
            uint16 hardware,
            uint16 frame,
            uint24 color1,
            uint24 color2,
            uint24 color3,
            uint24 color4,
            ShieldBadge shieldBadge
        );
}