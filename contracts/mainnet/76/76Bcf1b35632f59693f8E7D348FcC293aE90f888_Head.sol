// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/utils/Strings.sol";

library Head {
  using Strings for uint256;
  string constant HEAD_HEAD___ALASKAN_BLACK_BEAR =
    "iVBORw0KGgoAAAANSUhEUgAAAEAAAABACAMAAACdt4HsAAAAGXRFWHRTb2Z0d2FyZQBBZG9iZSBJbWFnZVJlYWR5ccllPAAAABhQTFRFNTU1AAAAMjIyLS0t8vLyAAAAAAAAAAAAtxDBtwAAAAZ0Uk5T//////8As7+kvwAAAIhJREFUeNrs1EsKgDAMBNDQocz9b6zEKn6wmhZEZbJoyWIeJYVY7iwT8GKAZKW9Bmhm9JxHSxsEjH7OdxCA7QoMzgD38ufA/gVPA4d8dAY/AIqQvNq/MaVFiAPYAAgDLqwA5i4ADcAooAio5GsbiSMxFdm40sh5o2itCxAgQIAAAQIEfAsYBBgA7DJMPObFMC4AAAAASUVORK5CYII=";

  string constant HEAD_HEAD___ALASKAN_PANDA_BEAR =
    "iVBORw0KGgoAAAANSUhEUgAAAEAAAABACAMAAACdt4HsAAAAGXRFWHRTb2Z0d2FyZQBBZG9iZSBJbWFnZVJlYWR5ccllPAAAABJQTFRF6+vrAAAANTU139/fLS0t////1ThdQQAAAAZ0Uk5T//////8As7+kvwAAAKdJREFUeNrs1NsKw0AIBFBnTf7/l2NEm0sx1IRCCzMPIfvgYS+izA8jBH4YgKVafQJgWOCFVhqrNjAgnli0AdmlD0xWv24/v2NC8xJj50CcpXuJefJILXwJgLwDih4Qbwfki94B4I3gxC0A2QXrv7YAF7D1EcoNlIDKMardRjoJivkRoG3ABN2Vl/UXEwlGZMpxcj3S8ArHOgECBAgQIECAwJ8BiwADAObUSq790lmUAAAAAElFTkSuQmCC";

  string constant HEAD_HEAD___ALASKAN_POLAR_BEAR =
    "iVBORw0KGgoAAAANSUhEUgAAAEAAAABACAMAAACdt4HsAAAAGXRFWHRTb2Z0d2FyZQBBZG9iZSBJbWFnZVJlYWR5ccllPAAAABhQTFRF6+vrAAAA39/f09PTAAAAAAAAAAAAAAAAQ0p3MgAAAAV0Uk5T/////wD7tg5TAAAAiElEQVR42uzUSwqAMAwE0NApzP1vrMQqfrCaFkRlsmjJYh4lhVjuLBPwYoBkpb0GaGb0nEdLGwSMfs53EIDtCgzOAPfy58D+BU8Dh3x0Bj8AipC82r8xpUWIA9gACAMurADmLgANwCigCKjkaxuJIzEV2bjSyHmjaK0LECBAgAABAgR8CxgEGADgdT14PqqFJgAAAABJRU5ErkJggg==";

  string constant HEAD_HEAD___GOLD_PANDA =
    "iVBORw0KGgoAAAANSUhEUgAAAEAAAABACAMAAACdt4HsAAAAGXRFWHRTb2Z0d2FyZQBBZG9iZSBJbWFnZVJlYWR5ccllPAAAABVQTFRF/+2o+dZOAAAA//jb5dWX2sNE////eqq0CwAAAAd0Uk5T////////ABpLA0YAAADASURBVHja7JThDoMgDITba/H9H1laUMMS0G7JsiW9HxZJ7qtScrR9KErA7wIA3GysARBhc8BlVUTwHADhKnEbEVn19+cA8zO52yTkGwFAMT/5o9r7uiBwBoXdyFeZ+KdT6MbW2yu27wKa/QIwBe/B2fj8BMUbgDbF5T9MAOpHcNyDhooC7P4Mio1RaQBIeAo6NBeKAl4JsxksAgWqJ6MuEU+kGgTaNU2Tu0gDjkTJWE9AAhKQgAQkIAEJ+C/ALsAAye1ZNeftIgsAAAAASUVORK5CYII=";

  string constant HEAD_HEAD___HIMALAYAN_BLACK_BEAR =
    "iVBORw0KGgoAAAANSUhEUgAAAEAAAABACAMAAACdt4HsAAAAGXRFWHRTb2Z0d2FyZQBBZG9iZSBJbWFnZVJlYWR5ccllPAAAAA9QTFRFNTU1AAAAMjIyLS0t////rVsosQAAAAV0Uk5T/////wD7tg5TAAAAlUlEQVR42uzUUQqEMAwE0EzH+59ZV+ua0m0wCuLC5EsK8yCpjU03ywS8FgBw4mgMwMywhdZyR+cBW4JWq34mANK6IpGZQScwM4O9iyafu0b0LeBR4Ed+1MTLgVIr+A3CIZbiBF64BQ8wCbRCkB8DPIRPPg34B8UgH2yk5UF9C7i00gC3UbTWBQgQIECAAAEC/gmYBRgAiy87enMCjCoAAAAASUVORK5CYII=";

  string constant HEAD_HEAD___HIMALAYAN_PANDA_BEAR =
    "iVBORw0KGgoAAAANSUhEUgAAAEAAAABACAMAAACdt4HsAAAAGXRFWHRTb2Z0d2FyZQBBZG9iZSBJbWFnZVJlYWR5ccllPAAAABJQTFRF6+vrAAAANTU139/fLS0t////1ThdQQAAAAZ0Uk5T//////8As7+kvwAAALJJREFUeNrs1OsKwyAMBeAcY9//lZfEC6PF1sNgbJD8sUjPV6sSOT4sSeB3AQAPE/cASimeQJSPPrEP+OsuQKKAPkEC8lYsUFs+1tAWYhMVxB7U4kn7qA3+MyZUUKcQwQG08fgy0Dde5gN3D1pubGIACg6QeQ36Iw2ciwP0mlfuGHVzAduAksBZWObXDQWqOtPr/E1HsrPTXstu8tTSgNFRsq0nkEACCSSQQAIJ/BfwEmAACepKTP4xsMkAAAAASUVORK5CYII=";

  string constant HEAD_HEAD___HIMALAYAN_POLAR_BEAR =
    "iVBORw0KGgoAAAANSUhEUgAAAEAAAABACAMAAACdt4HsAAAAGXRFWHRTb2Z0d2FyZQBBZG9iZSBJbWFnZVJlYWR5ccllPAAAAA9QTFRF6+vrAAAA39/f09PT////sy0tfgAAAAV0Uk5T/////wD7tg5TAAAAlUlEQVR42uzUUQqEMAwE0EzH+59ZV+ua0m0wCuLC5EsK8yCpjU03ywS8FgBw4mgMwMywhdZyR+cBW4JWq34mANK6IpGZQScwM4O9iyafu0b0LeBR4Ed+1MTLgVIr+A3CIZbiBF64BQ8wCbRCkB8DPIRPPg34B8UgH2yk5UF9C7i00gC3UbTWBQgQIECAAAEC/gmYBRgAiy87enMCjCoAAAAASUVORK5CYII=";

  string constant HEAD_HEAD___NEW_ENGLAND_BLACK_BEAR =
    "iVBORw0KGgoAAAANSUhEUgAAAEAAAABACAMAAACdt4HsAAAAGXRFWHRTb2Z0d2FyZQBBZG9iZSBJbWFnZVJlYWR5ccllPAAAAA9QTFRFNTU1AAAAMjIyLS0t////rVsosQAAAAV0Uk5T/////wD7tg5TAAAAkUlEQVR42uzU0QqAIAwF0Dvn/39zZmUqKc4gDO59ER92UGuDfxkQWBiQkNZuBBABQo3EXDsTAOw1wL0aAUUVNQK1oMYreBk8QPcNysinwEN96xKrAy7mqDcBp+DcLejMV8gA1ZkfKQfE2s5avIGagSBk3dCu70yk0E8pzXHSH2mSwrFOgAABAgQIECDwM2ATYAAAhzt+t498NwAAAABJRU5ErkJggg==";

  string constant HEAD_HEAD___NEW_ENGLAND_PANDA_BEAR =
    "iVBORw0KGgoAAAANSUhEUgAAAEAAAABACAMAAACdt4HsAAAAGXRFWHRTb2Z0d2FyZQBBZG9iZSBJbWFnZVJlYWR5ccllPAAAABJQTFRF6+vrAAAANTU139/fLS0t////1ThdQQAAAAZ0Uk5T//////8As7+kvwAAAKNJREFUeNrs1MEOwyAMA9A4Yf//y2PJqESldjXdYZOcC3DwEyIo9rhZJuCHAQAnx88A3B2Zy+j7SAIOWBbqxAHNbarWQL5B2Ov2dYG+BthHtLq3jZUGMrcBvtKFCVjqwheAesTcNrqN8z/g24gRH52k2zgX/w9iztPATjjMXwRiAehCbPHj/NlEQieqgMWRBoyJorEuQIAAAQIECBDwX8BTgAEA4sVLMdWBDS4AAAAASUVORK5CYII=";

  string constant HEAD_HEAD___NEW_ENGLAND_POLAR_BEAR =
    "iVBORw0KGgoAAAANSUhEUgAAAEAAAABACAMAAACdt4HsAAAAGXRFWHRTb2Z0d2FyZQBBZG9iZSBJbWFnZVJlYWR5ccllPAAAAA9QTFRF6+vrAAAA39/f09PT////sy0tfgAAAAV0Uk5T/////wD7tg5TAAAAkUlEQVR42uzU0QqAIAwF0Dvn/39zZmUqKc4gDO59ER92UGuDfxkQWBiQkNZuBBABQo3EXDsTAOw1wL0aAUUVNQK1oMYreBk8QPcNysinwEN96xKrAy7mqDcBp+DcLejMV8gA1ZkfKQfE2s5avIGagSBk3dCu70yk0E8pzXHSH2mSwrFOgAABAgQIECDwM2ATYAAAhzt+t498NwAAAABJRU5ErkJggg==";

  string constant HEAD_HEAD___REVERSE_PANDA_BEAR =
    "iVBORw0KGgoAAAANSUhEUgAAAEAAAABACAMAAACdt4HsAAAAGXRFWHRTb2Z0d2FyZQBBZG9iZSBJbWFnZVJlYWR5ccllPAAAABJQTFRFNTU16+vrAAAALS0t39/f////w0HIeQAAAAZ0Uk5T//////8As7+kvwAAAK5JREFUeNrs1NEOwyAIBVDuxf3/L49ZNbSLjdiXLYEXW9N7kopBXg9LEvhZgOTC1hwgAB6hWm5rHYAFpZU9IgaUYt+LK3sthZEzKKipFhaxOENdYA0CfVHG2tjzGOtMWAYkBIw83ANDAK4A9oDWhU8pN35hXIL5Kd4eortG4S6onEuDwJcQvUhXQMOACeri0/zNRKIRvcitkUa6iZJjPYEEEkgggQQSSOCfgLcAAwCFo0qCYOUzAAAAAABJRU5ErkJggg==";

  string constant HEAD_HEAD___SASKATCHEWAN_BLACK_BEAR =
    "iVBORw0KGgoAAAANSUhEUgAAAEAAAABACAMAAACdt4HsAAAAGXRFWHRTb2Z0d2FyZQBBZG9iZSBJbWFnZVJlYWR5ccllPAAAAA9QTFRFNTU1AAAAMjIyLS0t////rVsosQAAAAV0Uk5T/////wD7tg5TAAAAk0lEQVR42uzU4QqAIAwE4J3X+z9zKQYlOZ39Kbj9MaR9oJOz7WWZgO8CAAYbPgAzyx0olde8MQ/k3wvRrFGgrQDAp34icAec7e9OYfIA3wUwPQQfSLVWgZSuAl8CXBjjHQhOgc0dMAjcBK+/Hyggz/d8fHX7nUQ6goC1umkyijTgTBTFugABAgQIECBAwL+AXYABAN5nO1o/F1OGAAAAAElFTkSuQmCC";

  string constant HEAD_HEAD___SASKATCHEWAN_PANDA_BEAR =
    "iVBORw0KGgoAAAANSUhEUgAAAEAAAABACAMAAACdt4HsAAAAGXRFWHRTb2Z0d2FyZQBBZG9iZSBJbWFnZVJlYWR5ccllPAAAABJQTFRFNTU1AAAA6+vr09PTLS0t////LI6PZwAAAAZ0Uk5T//////8As7+kvwAAAKxJREFUeNrs1EsOwyAMBFBPcO9/5RoCqVMJlGk2qTTe8FHmEWEJe90sE/BYAMCFrTkAM8MeapW2rgMWwa1XTI0D3OP7LVUs3cHcgXs7uJ8fgjN3UIkI1r/+DFwbe9DySAItdwAxoYCUS5NfAMMYaWAIR54GslDXBWQXvoDCduEmcBYW+TlQTkChgRDKABzz/OJFqilvtcqvnjSk0rMuQIAAAQIECBDwX8BbgAEAgw5KgqceTiQAAAAASUVORK5CYII=";

  string constant HEAD_HEAD___SASKATCHEWAN_POLAR_BEAR =
    "iVBORw0KGgoAAAANSUhEUgAAAEAAAABACAMAAACdt4HsAAAAGXRFWHRTb2Z0d2FyZQBBZG9iZSBJbWFnZVJlYWR5ccllPAAAAA9QTFRF6+vrAAAA39/f09PT////sy0tfgAAAAV0Uk5T/////wD7tg5TAAAAk0lEQVR42uzU4QqAIAwE4J3X+z9zKQYlOZ39Kbj9MaR9oJOz7WWZgO8CAAYbPgAzyx0olde8MQ/k3wvRrFGgrQDAp34icAec7e9OYfIA3wUwPQQfSLVWgZSuAl8CXBjjHQhOgc0dMAjcBK+/Hyggz/d8fHX7nUQ6goC1umkyijTgTBTFugABAgQIECBAwL+AXYABAN5nO1o/F1OGAAAAAElFTkSuQmCC";

  function getAsset(uint256 assetNum) external pure returns (string memory) {
    if (assetNum == 0) {
      return HEAD_HEAD___ALASKAN_BLACK_BEAR;
    } else if (assetNum == 1) {
      return HEAD_HEAD___ALASKAN_PANDA_BEAR;
    } else if (assetNum == 2) {
      return HEAD_HEAD___ALASKAN_POLAR_BEAR;
    } else if (assetNum == 3) {
      return HEAD_HEAD___GOLD_PANDA;
    } else if (assetNum == 4) {
      return HEAD_HEAD___HIMALAYAN_BLACK_BEAR;
    } else if (assetNum == 5) {
      return HEAD_HEAD___HIMALAYAN_PANDA_BEAR;
    } else if (assetNum == 6) {
      return HEAD_HEAD___HIMALAYAN_POLAR_BEAR;
    } else if (assetNum == 7) {
      return HEAD_HEAD___NEW_ENGLAND_BLACK_BEAR;
    } else if (assetNum == 8) {
      return HEAD_HEAD___NEW_ENGLAND_PANDA_BEAR;
    } else if (assetNum == 9) {
      return HEAD_HEAD___NEW_ENGLAND_POLAR_BEAR;
    } else if (assetNum == 10) {
      return HEAD_HEAD___REVERSE_PANDA_BEAR;
    } else if (assetNum == 11) {
      return HEAD_HEAD___SASKATCHEWAN_BLACK_BEAR;
    } else if (assetNum == 12) {
      return HEAD_HEAD___SASKATCHEWAN_PANDA_BEAR;
    } else if (assetNum == 13) {
      return HEAD_HEAD___SASKATCHEWAN_POLAR_BEAR;
    }
    return HEAD_HEAD___ALASKAN_BLACK_BEAR;
  }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Strings.sol)

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";
    uint8 private constant _ADDRESS_LENGTH = 20;

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        // Inspired by OraclizeAPI's implementation - MIT licence
        // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol

        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0x00";
        }
        uint256 temp = value;
        uint256 length = 0;
        while (temp != 0) {
            length++;
            temp >>= 8;
        }
        return toHexString(value, length);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _HEX_SYMBOLS[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
    }

    /**
     * @dev Converts an `address` with fixed length of 20 bytes to its not checksummed ASCII `string` hexadecimal representation.
     */
    function toHexString(address addr) internal pure returns (string memory) {
        return toHexString(uint256(uint160(addr)), _ADDRESS_LENGTH);
    }
}