// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@/contracts/utils/Constants.sol";
import {IColormapRegistry} from "@/contracts/interfaces/IColormapRegistry.sol";
import {IPaletteGenerator} from "@/contracts/interfaces/IPaletteGenerator.sol";

/// @title An on-chain registry for colormaps.
/// @author fiveoutofnine
contract ColormapRegistry is IColormapRegistry {
    // -------------------------------------------------------------------------
    // Storage
    // -------------------------------------------------------------------------

    /// @inheritdoc IColormapRegistry
    mapping(bytes32 => SegmentData) public override segments;

    /// @inheritdoc IColormapRegistry
    mapping(bytes32 => IPaletteGenerator) public override paletteGenerators;

    // -------------------------------------------------------------------------
    // Modifiers
    // -------------------------------------------------------------------------

    /// @dev Reverts a function if a colormap does not exist.
    /// @param _colormapHash Hash of the colormap's definition.
    modifier colormapExists(bytes32 _colormapHash) {
        SegmentData memory segmentData = segments[_colormapHash];

        // Revert if a colormap corresponding to `_colormapHash` has never been
        // set.
        if (
            // Segment data is uninitialized.  We don't need to check `g` and
            // `b` because the segment data would've never been initialized if
            // any of `r`, `g`, or `b` were 0.
            segmentData.r == 0 &&
            // Palette generator is uninitialized.
            address(paletteGenerators[_colormapHash]) == address(0)
        ) {
            revert ColormapDoesNotExist(_colormapHash);
        }

        _;
    }

    // -------------------------------------------------------------------------
    // Actions
    // -------------------------------------------------------------------------

    /// @inheritdoc IColormapRegistry
    function register(IPaletteGenerator _paletteGenerator) external {
        bytes32 colormapHash = _computeColormapHash(_paletteGenerator);

        // Store palette generator.
        paletteGenerators[colormapHash] = _paletteGenerator;

        // Emit event.
        emit RegisterColormap(colormapHash, _paletteGenerator);
    }

    /// @inheritdoc IColormapRegistry
    function register(SegmentData memory _segmentData) external {
        bytes32 colormapHash = _computeColormapHash(_segmentData);

        // Check if `_segmentData` is valid.
        _checkSegmentDataValidity(_segmentData.r);
        _checkSegmentDataValidity(_segmentData.g);
        _checkSegmentDataValidity(_segmentData.b);

        // Store segment data.
        segments[colormapHash] = _segmentData;

        // Emit event.
        emit RegisterColormap(colormapHash, _segmentData);
    }

    // -------------------------------------------------------------------------
    // View
    // -------------------------------------------------------------------------

    /// @inheritdoc IColormapRegistry
    function getValue(bytes32 _colormapHash, uint256 _position)
        external
        view
        colormapExists(_colormapHash)
        returns (
            uint256,
            uint256,
            uint256
        )
    {
        IPaletteGenerator paletteGenerator = paletteGenerators[_colormapHash];

        // Compute using the palette generator, if there exists one.
        if (address(paletteGenerator) != address(0)) {
            return (
                paletteGenerator.r(_position),
                paletteGenerator.g(_position),
                paletteGenerator.b(_position)
            );
        }

        // Compute the value with a piece-wise interpolation on the segments
        // given by the segment data.
        SegmentData memory segmentData = segments[_colormapHash];
        return (
            _computeLinearInterpolationFPM(segmentData.r, _position),
            _computeLinearInterpolationFPM(segmentData.g, _position),
            _computeLinearInterpolationFPM(segmentData.b, _position)
        );
    }

    /// @inheritdoc IColormapRegistry
    function getValueAsUint8(bytes32 _colormapHash, uint8 _position)
        public
        view
        colormapExists(_colormapHash)
        returns (
            uint8,
            uint8,
            uint8
        )
    {
        IPaletteGenerator paletteGenerator = paletteGenerators[_colormapHash];

        // Compute using the palette generator, if there exists one.
        if (address(paletteGenerator) != address(0)) {
            unchecked {
                // All functions in {IPaletteGenerator} represent a position in
                // the colormap as a 18 decimal fixed point number in [0, 1], so
                // we must convert it.
                uint256 positionAsFixedPointDecimal = FIXED_POINT_COLOR_VALUE_SCALAR *
                        _position;

                // This function returns `uint8` for each of the R, G, and B's
                // values, while all functions in {IPaletteGenerator} use the
                // 18 decimal fixed point representation, so we must convert it
                // back.
                return (
                    uint8(
                        paletteGenerator.r(positionAsFixedPointDecimal) /
                            FIXED_POINT_COLOR_VALUE_SCALAR
                    ),
                    uint8(
                        paletteGenerator.g(positionAsFixedPointDecimal) /
                            FIXED_POINT_COLOR_VALUE_SCALAR
                    ),
                    uint8(
                        paletteGenerator.b(positionAsFixedPointDecimal) /
                            FIXED_POINT_COLOR_VALUE_SCALAR
                    )
                );
            }
        }

        // Compute the value with a piece-wise interpolation on the segments
        // given by the segment data.
        SegmentData memory segmentData = segments[_colormapHash];
        return (
            _computeLinearInterpolation(segmentData.r, _position),
            _computeLinearInterpolation(segmentData.g, _position),
            _computeLinearInterpolation(segmentData.b, _position)
        );
    }

    /// @inheritdoc IColormapRegistry
    function getValueAsHexString(bytes32 _colormapHash, uint8 _position)
        external
        view
        returns (string memory)
    {
        (uint8 r, uint8 g, uint8 b) = getValueAsUint8(_colormapHash, _position);

        return
            string(
                abi.encodePacked(
                    HEXADECIMAL_DIGITS[r >> 4],
                    HEXADECIMAL_DIGITS[r & 0xF],
                    HEXADECIMAL_DIGITS[g >> 4],
                    HEXADECIMAL_DIGITS[g & 0xF],
                    HEXADECIMAL_DIGITS[b >> 4],
                    HEXADECIMAL_DIGITS[b & 0xF]
                )
            );
    }

    // -------------------------------------------------------------------------
    // Helpers
    // -------------------------------------------------------------------------

    /// @notice Checks if a colormap exists.
    /// @dev The function reverts if the colormap corresponding to
    /// `_colormapHash` was never registered.
    /// @param _colormapHash Hash of the colormap's definition.
    function _checkColormapDoesNotExist(bytes32 _colormapHash) internal view {
        SegmentData memory segmentData = segments[_colormapHash];

        // Revert if a colormap corresponding to `colormapHash` has already
        // been set.
        if (
            // Segment data is initialized. We don't need to check `g` and `b`
            // because the segment data would've never been initialized if any
            // of `r`, `g`, or `b` were 0.
            (segmentData.r > 0) ||
            // Palette generator is initialized.
            address(paletteGenerators[_colormapHash]) != address(0)
        ) {
            revert ColormapAlreadyExists(_colormapHash);
        }
    }

    /// @notice Checks if a `uint256` corresponds to a valid segment data.
    /// @dev The function reverts if `_segmentData` is not a valid
    /// representation for a colormap.
    /// @param _segmentData Segment data for 1 of R, G, or B. See
    /// {IColormapRegistry} for its representation.
    function _checkSegmentDataValidity(uint256 _segmentData) internal pure {
        uint256 prevPosition = (_segmentData >> 16) & 0xFF;

        // Revert if the colormap isn't defined from the start.
        if (prevPosition > 0) {
            revert SegmentDataInvalid(_segmentData);
        }

        for (
            // We shift `_segmentData` right by 24 because the first segment was
            // read already.
            uint256 partialSegmentData = _segmentData >> 24;
            partialSegmentData > 0;
            partialSegmentData >>= 24
        ) {
            uint256 position = (partialSegmentData >> 16) & 0xFF;

            // Revert if the position did not increase.
            if (position <= prevPosition) {
                revert SegmentDataInvalid(_segmentData);
            }

            prevPosition = (partialSegmentData >> 16) & 0xFF;
        }

        // Revert if the colormap isn't defined til the end.
        if (prevPosition < 0xFF) {
            revert SegmentDataInvalid(_segmentData);
        }
    }

    /// @notice Computes the hash of a colormap defined via a palette generator.
    /// @dev The function reverts if the colormap already exists.
    /// @param _paletteGenerator Palette generator for the colormap.
    /// @return bytes32 Hash of `_paletteGenerator`.
    function _computeColormapHash(IPaletteGenerator _paletteGenerator)
        internal
        view
        returns (bytes32)
    {
        // Compute hash.
        bytes32 colormapHash = keccak256(abi.encodePacked(_paletteGenerator));

        // Revert if colormap does not exist.
        _checkColormapDoesNotExist(colormapHash);

        return colormapHash;
    }

    /// @notice Computes the hash of a colormap defined via segment data.
    /// @dev The function reverts if the colormap already exists.
    /// @param _segmentData Segment data for the colormap. See
    /// {IColormapRegistry} for its representation.
    /// @return bytes32 Hash of the contents of `_segmentData`.
    function _computeColormapHash(SegmentData memory _segmentData)
        internal
        view
        returns (bytes32)
    {
        // Compute hash.
        bytes32 colormapHash = keccak256(
            abi.encodePacked(_segmentData.r, _segmentData.g, _segmentData.b)
        );

        // Revert if colormap does not exist.
        _checkColormapDoesNotExist(colormapHash);

        return colormapHash;
    }

    /// @notice Computes the value at the position `_position` along some
    /// segment data defined by `_segmentData`.
    /// @param _segmentData Segment data for 1 of R, G, or B. See
    /// {IColormapRegistry} for its representation.
    /// @param _position Position along the colormap.
    /// @return uint8 Intensity of the color at the position in the colormap.
    function _computeLinearInterpolation(uint256 _segmentData, uint8 _position)
        internal
        pure
        returns (uint8)
    {
        // We loop until we find the segment with the greatest position less
        // than `_position`.
        while ((_segmentData >> 40) & 0xFF < _position) {
            _segmentData >>= 24;
        }

        // Retrieve the start and end of the identified segment.
        uint256 segmentStart = _segmentData & 0xFFFFFF;
        uint256 segmentEnd = (_segmentData >> 24) & 0xFFFFFF;

        // Retrieve start/end position w.r.t. the entire colormap.
        uint256 startPosition = (segmentStart >> 16) & 0xFF;
        uint256 endPosition = (segmentEnd >> 16) & 0xFF;

        // Retrieve start/end intensities.
        uint256 startIntensity = segmentStart & 0xFF;
        uint256 endIntensity = (segmentEnd >> 8) & 0xFF;

        // Compute the value with a piece-wise linear interpolation on the
        // segments.
        unchecked {
            // This will never underflow because we ensure the start segment's
            // position is less than or equal to `_position`.
            uint256 positionChange = _position - startPosition;

            // This will never be 0 because we ensure each segment must increase
            // in {ColormapRegistry.register} via
            // {ColormapRegistry._checkSegmentDataValidity}.
            uint256 segmentLength = endPosition - startPosition;

            // Check if end intensity is larger to prevent under/overflowing (as
            // well as to compute the correct value).
            if (endIntensity >= startIntensity) {
                return
                    uint8(
                        startIntensity +
                            ((endIntensity - startIntensity) * positionChange) /
                            segmentLength
                    );
            }

            return
                uint8(
                    startIntensity -
                        ((startIntensity - endIntensity) * positionChange) /
                        segmentLength
                );
        }
    }

    /// @notice Computes the value at the position `_position` along some
    /// segment data defined by `_segmentData`.
    /// @param _segmentData Segment data for 1 of R, G, or B. See
    /// {IColormapRegistry} for its representation.
    /// @param _position 18 decimal fixed-point number in [0, 1] representing
    /// the position along the colormap.
    /// @return uint256 Intensity of the color at the position in the colormap.
    function _computeLinearInterpolationFPM(
        uint256 _segmentData,
        uint256 _position
    ) internal pure returns (uint256) {
        unchecked {
            // We need to truncate `_position` to be in [0, 0xFF] pre-scaling.
            _position = _position > 0xFF * FIXED_POINT_COLOR_VALUE_SCALAR
                ? 0xFF * FIXED_POINT_COLOR_VALUE_SCALAR
                : _position;

            // We look until we find the segment with the greatest position less
            // than `_position`.
            while (
                ((_segmentData >> 40) & 0xFF) * FIXED_POINT_COLOR_VALUE_SCALAR <
                _position
            ) {
                _segmentData >>= 24;
            }

            // Retrieve the start and end of the identified segment.
            uint256 segmentStart = _segmentData & 0xFFFFFF;
            uint256 segmentEnd = (_segmentData >> 24) & 0xFFFFFF;

            // Retrieve start/end position w.r.t. the entire colormap and
            // convert them to the 18 decimal fixed point number representation.
            uint256 startPosition = ((segmentStart >> 16) & 0xFF) *
                FIXED_POINT_COLOR_VALUE_SCALAR;
            uint256 endPosition = ((segmentEnd >> 16) & 0xFF) *
                FIXED_POINT_COLOR_VALUE_SCALAR;

            // Retrieve start/end intensities and convert them to the 18 decimal
            // fixed point number representation.
            uint256 startIntensity = (segmentStart & 0xFF) *
                FIXED_POINT_COLOR_VALUE_SCALAR;
            uint256 endIntensity = ((segmentEnd >> 8) & 0xFF) *
                FIXED_POINT_COLOR_VALUE_SCALAR;

            // This will never underflow because we ensure the start segment's
            // position is less than or equal to `_position`.
            uint256 positionChange = _position - startPosition;

            // This will never be 0 because we ensure each segment must increase
            // in {ColormapRegistry.register} via
            // {ColormapRegistry._checkSegmentDataValidity}.
            uint256 segmentLength = endPosition - startPosition;

            // Check if end intensity is larger to prevent under/overflowing (as
            // well as to compute the correct value).
            if (endIntensity >= startIntensity) {
                return
                    startIntensity +
                    ((endIntensity - startIntensity) * positionChange) /
                    segmentLength;
            }

            return
                startIntensity -
                ((startIntensity - endIntensity) * positionChange) /
                segmentLength;
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import {IPaletteGenerator} from "@/contracts/interfaces/IPaletteGenerator.sol";

/// @title The interface for the colormap registry.
/// @author fiveoutofnine
/// @dev A colormap may be defined in 2 ways: (1) via segment data and (2) via a
/// ``palette generator.''
///     1. via segment data
///     2. or via a palette generator ({IPaletteGenerator}).
/// Segment data contains 1 `uint256` each for red, green, and blue describing
/// their intensity values along the colormap. Each `uint256` contains 24-bit
/// words bitpacked together with the following structure (bits are
/// right-indexed):
///     | Bits      | Meaning                                              |
///     | --------- | ---------------------------------------------------- |
///     | `23 - 16` | Position in the colormap the segment begins from     |
///     | `15 - 08` | Intensity of R, G, or B the previous segment ends at |
///     | `07 - 00` | Intensity of R, G, or B the next segment starts at   |
/// Given some position, the output will be computed via linear interpolations
/// on the segment data for R, G, and B. A maximum of 10 of these segments fit
/// within 256 bits, so up to 9 segments can be defined. If you need more
/// granularity or a nonlinear palette function, you may implement
/// {IPaletteGenerator} and define a colormap with that.
interface IColormapRegistry {
    // -------------------------------------------------------------------------
    // Errors
    // -------------------------------------------------------------------------

    /// @notice Emitted when a colormap already exists.
    /// @param _colormapHash Hash of the colormap's definition.
    error ColormapAlreadyExists(bytes32 _colormapHash);

    /// @notice Emitted when a colormap does not exist.
    /// @param _colormapHash Hash of the colormap's definition.
    error ColormapDoesNotExist(bytes32 _colormapHash);

    /// @notice Emitted when a segment data used to define a colormap does not
    /// follow the representation outlined in {IColormapRegistry}.
    /// @param _segmentData Segment data for 1 of R, G, or B. See
    /// {IColormapRegistry} for its representation.
    error SegmentDataInvalid(uint256 _segmentData);

    // -------------------------------------------------------------------------
    // Structs
    // -------------------------------------------------------------------------

    /// @notice Segment data that defines a colormap when read via piece-wise
    /// linear interpolation.
    /// @dev Each param contains 24-bit words, so each one may contain at most
    /// 9 (24*10 - 1) segments. See {IColormapRegistry} for how the segment data
    /// should be structured.
    /// @param r Segment data for red's color value along the colormap.
    /// @param g Segment data for green's color value along the colormap.
    /// @param b Segment data for blue's color value along the colormap.
    struct SegmentData {
        uint256 r;
        uint256 g;
        uint256 b;
    }

    // -------------------------------------------------------------------------
    // Events
    // -------------------------------------------------------------------------

    /// @notice Emitted when a colormap is registered via a palette generator
    /// function.
    /// @param _hash Hash of `_paletteGenerator`.
    /// @param _paletteGenerator Instance of {IPaletteGenerator} for the
    /// colormap.
    event RegisterColormap(bytes32 _hash, IPaletteGenerator _paletteGenerator);

    /// @notice Emitted when a colormap is registered via segment data.
    /// @param _hash Hash of `_segmentData`.
    /// @param _segmentData Segment data defining the colormap.
    event RegisterColormap(bytes32 _hash, SegmentData _segmentData);

    // -------------------------------------------------------------------------
    // Storage
    // -------------------------------------------------------------------------

    /// @param _colormapHash Hash of the colormap's definition (segment data).
    /// @return uint256 Segment data for red's color value along the colormap.
    /// @return uint256 Segment data for green's color value along the colormap.
    /// @return uint256 Segment data for blue's color value along the colormap.
    function segments(bytes32 _colormapHash)
        external
        view
        returns (
            uint256,
            uint256,
            uint256
        );

    /// @param _colormapHash Hash of the colormap's definition (palette
    /// generator).
    /// @return IPaletteGenerator Instance of {IPaletteGenerator} for the
    /// colormap.
    function paletteGenerators(bytes32 _colormapHash)
        external
        view
        returns (IPaletteGenerator);

    // -------------------------------------------------------------------------
    // Actions
    // -------------------------------------------------------------------------

    /// @notice Register a colormap with a palette generator.
    /// @param _paletteGenerator Instance of {IPaletteGenerator} for the
    /// colormap.
    function register(IPaletteGenerator _paletteGenerator) external;

    /// @notice Register a colormap with segment data that will be read via
    /// piece-wise linear interpolation.
    /// @dev See {IColormapRegistry} for how the segment data should be
    /// structured.
    /// @param _segmentData Segment data defining the colormap.
    function register(SegmentData memory _segmentData) external;

    // -------------------------------------------------------------------------
    // View
    // -------------------------------------------------------------------------

    /// @notice Get the red, green, and blue color values of a color in a
    /// colormap at some position.
    /// @dev Each color value will be returned as a 18 decimal fixed-point
    /// number in [0, 1]. Note that the function *will not* revert if
    /// `_position` is an invalid input (i.e. greater than 1e18). This
    /// responsibility is left to the implementation of {IPaletteGenerator}s.
    /// @param _colormapHash Hash of the colormap's definition.
    /// @param _position 18 decimal fixed-point number in [0, 1] representing
    /// the position in the colormap (i.e. 0 being min, and 1 being max).
    /// @return uint256 Intensity of red in that color at the position
    /// `_position`.
    /// @return uint256 Intensity of green in that color at the position
    /// `_position`.
    /// @return uint256 Intensity of blue in that color at the position
    /// `_position`.
    function getValue(bytes32 _colormapHash, uint256 _position)
        external
        view
        returns (
            uint256,
            uint256,
            uint256
        );

    /// @notice Get the red, green, and blue color values of a color in a
    /// colormap at some position.
    /// @dev Each color value will be returned as a `uint8` number in [0, 255].
    /// @param _colormapHash Hash of the colormap's definition.
    /// @param _position Position in the colormap (i.e. 0 being min, and 255
    /// being max).
    /// @return uint8 Intensity of red in that color at the position
    /// `_position`.
    /// @return uint8 Intensity of green in that color at the position
    /// `_position`.
    /// @return uint8 Intensity of blue in that color at the position
    /// `_position`.
    function getValueAsUint8(bytes32 _colormapHash, uint8 _position)
        external
        view
        returns (
            uint8,
            uint8,
            uint8
        );

    /// @notice Get the hexstring for a color in a colormap at some position.
    /// @param _colormapHash Hash of the colormap's definition.
    /// @param _position Position in the colormap (i.e. 0 being min, and 255
    /// being max).
    /// @return string Hexstring excluding ``#'' (e.g. `007CFF`) of the color
    /// at the position `_position`.
    function getValueAsHexString(bytes32 _colormapHash, uint8 _position)
        external
        view
        returns (string memory);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

/// @title The interface for a palette generator.
/// @author fiveoutofnine
/// @dev `IPaletteGenerator` contains generator functions for a color's red,
/// green, and blue color values. Each of these functions is intended to take in
/// a 18 decimal fixed-point number in [0, 1] representing the position in the
/// colormap and return the corresponding 18 decimal fixed-point number in
/// [0, 1] representing the value of each respective color.
interface IPaletteGenerator {
    // -------------------------------------------------------------------------
    // Errors
    // -------------------------------------------------------------------------

    /// @notice Reverts if the position is not a valid input.
    /// @dev The position is not a valid input if it is greater than 1e18.
    /// @param _position Position in the colormap.
    error InvalidPosition(uint256 _position);

    // -------------------------------------------------------------------------
    // Generators
    // -------------------------------------------------------------------------

    /// @notice Computes the intensity of red of the palette at some position.
    /// @dev The function should revert if `_position` is not a valid input
    /// (i.e. greater than 1e18). Also, the return value for all inputs must be
    /// a 18 decimal.
    /// @param _position Position in the colormap.
    /// @return uint256 Intensity of red in that color at the position
    /// `_position`.
    function r(uint256 _position) external pure returns (uint256);

    /// @notice Computes the intensity of green of the palette at some position.
    /// @dev The function should revert if `_position` is not a valid input
    /// (i.e. greater than 1e18). Also, the return value for all inputs must be
    /// a 18 decimal.
    /// @param _position Position in the colormap.
    /// @return uint256 Intensity of green in that color at the position
    /// `_position`.
    function g(uint256 _position) external pure returns (uint256);

    /// @notice Computes the intensity of blue of the palette at some position.
    /// @dev The function should revert if `_position` is not a valid input
    /// (i.e. greater than 1e18). Also, the return value for all inputs must be
    /// a 18 decimal.
    /// @param _position Position in the colormap.
    /// @return uint256 Intensity of blue in that color at the position
    /// `_position`.
    function b(uint256 _position) external pure returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

// -----------------------------------------------------------------------------
// Scalars
// -----------------------------------------------------------------------------

// A scalar to convert a number from [0, 255] to an 18 decimal fixed-point
// number in [0, 1] (i.e. 1e18 / 255).
uint256 constant FIXED_POINT_COLOR_VALUE_SCALAR = 3_921_568_627_450_980;

// -----------------------------------------------------------------------------
// Miscellaneous
// -----------------------------------------------------------------------------

// A look-up table to simplify the conversion from number to hexstring.
bytes32 constant HEXADECIMAL_DIGITS = "0123456789ABCDEF";