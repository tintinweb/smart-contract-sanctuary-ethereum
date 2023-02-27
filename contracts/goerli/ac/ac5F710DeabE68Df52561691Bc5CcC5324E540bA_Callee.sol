/**
 *Submitted for verification at Etherscan.io on 2023-02-27
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

library RenderDays {
    string constant g_transform = '<g transform=';
    string constant seven_segment_1 = '"translate(400, 520) scale(0.60, 0.60)" >';
    string constant seven_segment_2 = '"translate(345, 520) scale(0.60, 0.60)" >';
    string constant seven_segment_3 = '"translate(290, 520) scale(0.60, 0.60)" >';
    string constant a = '<line id="a" x1="130" y1="25" x2="80" y2="25" stroke=';
    string constant b = '<line id="b" x1="135" y1="30" x2="135" y2="80" stroke=';
    string constant c = '<line id="c" x1="135" y1="90" x2="135" y2="140" stroke=';
    string constant d = '<line id="g" x1="80" y1="145" x2="130" y2="145" stroke=';
    string constant e = '<line id="e" x1="75" y1="90" x2="75" y2="140" stroke=';
    string constant f = '<line id="f" x1="75" y1="30" x2="75" y2="80" stroke=';
    string constant g = '<line id="g" x1="80" y1="85" x2="130" y2="85" stroke=';
    string constant on = '"white" stroke-width="5" />"';
    string constant off = '"black" stroke-width="5" />"';
    string constant g_end = '</g>';

    function get1(uint256 value) internal pure returns (string memory number) {
        if (value > 9) {
            number = string(abi.encodePacked(
                a,
               off,
                b,
               off,
                c,
               off,
               d,
               off
            ));

            number = string(abi.encodePacked(
                number,
                e,
                off,
                f,
                off
            ));

            return string(abi.encodePacked(
                g_transform,
                seven_segment_1,
                number,
                g,
                off,
                g_end
            )); 
        }

        if (value == 0) {
            number = string(abi.encodePacked(
                a,
               on,
                b,
               on,
                c,
               on,
               d,
               on
            ));

            number = string(abi.encodePacked(
                number,
                e,
                on,
                f,
                on
            ));

            return string(abi.encodePacked(
                g_transform,
                seven_segment_1,
                number,
                g,
                off,
                g_end
            )); 
        }

        if (value == 1) {
            number = string(abi.encodePacked(
                a,
               off,
                b,
               on,
                c,
               on,
               d,
               off
            ));

            number = string(abi.encodePacked(
                number,
                e,
                off,
                f,
                off
            ));

            return string(abi.encodePacked(
                g_transform,
                seven_segment_1,
                number,
                g,
                off,
                g_end
            )); 
        }

        if (value == 2) {
            number = string(abi.encodePacked(
                a,
               on,
                b,
               on,
                c,
               off,
               d,
               on
            ));

            number = string(abi.encodePacked(
                number,
                e,
                on,
                f,
                off
            ));

            return string(abi.encodePacked(
                g_transform,
                seven_segment_1,
                number,
                g,
                on,
                g_end
            )); 
        }

        if (value == 3) {
            number = string(abi.encodePacked(
                a,
               on,
                b,
               on,
                c,
               on,
               d,
               on
            ));

            number = string(abi.encodePacked(
                number,
                e,
                off,
                f,
                off
            ));

            return string(abi.encodePacked(
                g_transform,
                seven_segment_1,
                number,
                g,
                on,
                g_end
            )); 
        }

        if (value == 4) {
            number = string(abi.encodePacked(
                a,
               off,
                b,
               on,
                c,
               on,
               d,
               off
            ));

            number = string(abi.encodePacked(
                number,
                e,
                off,
                f,
                on
            ));

            return string(abi.encodePacked(
                g_transform,
                seven_segment_1,
                number,
                g,
                on,
                g_end
            )); 
        }

        if (value == 5) {
            number = string(abi.encodePacked(
                a,
               on,
                b,
               off,
                c,
               on,
               d,
               on
            ));

            number = string(abi.encodePacked(
                number,
                e,
                off,
                f,
                on
            ));

            return string(abi.encodePacked(
                g_transform,
                seven_segment_1,
                number,
                g,
                on,
                g_end
            )); 
        }

        if (value == 6) {
            number = string(abi.encodePacked(
                a,
               on,
                b,
               off,
                c,
               on,
               d,
               on
            ));

            number = string(abi.encodePacked(
                number,
                e,
                on,
                f,
                on
            ));

            return string(abi.encodePacked(
                g_transform,
                seven_segment_1,
                number,
                g,
                on,
                g_end
            )); 
        }

        if (value == 7) {
            number = string(abi.encodePacked(
                a,
               on,
                b,
               on,
                c,
               on,
               d,
               off
            ));

            number = string(abi.encodePacked(
                number,
                e,
                off,
                f,
                off
            ));

            return string(abi.encodePacked(
                g_transform,
                seven_segment_1,
                number,
                g,
                off,
                g_end
            )); 
        }

        if (value == 8) {
            number = string(abi.encodePacked(
                a,
               on,
                b,
               on,
                c,
               on,
               d,
               on
            ));

            number = string(abi.encodePacked(
                number,
                e,
                on,
                f,
                on
            ));

            return string(abi.encodePacked(
                g_transform,
                seven_segment_1,
                number,
                g,
                on,
                g_end
            )); 
        }

        if (value == 9) {
            number = string(abi.encodePacked(
                a,
               on,
                b,
               on,
                c,
               on,
               d,
               off
            ));

            number = string(abi.encodePacked(
                number,
                e,
                off,
                f,
                on
            ));

            return string(abi.encodePacked(
                g_transform,
                seven_segment_1,
                number,
                g,
                on,
                g_end
            )); 
        }
    }

    function get2(uint256 value) internal pure returns (string memory number) {
        if (value > 9) {
            number = string(abi.encodePacked(
                a,
               off,
                b,
               off,
                c,
               off,
               d,
               off
            ));

            number = string(abi.encodePacked(
                number,
                e,
                off,
                f,
                off
            ));

            return string(abi.encodePacked(
                g_transform,
                seven_segment_2,
                number,
                g,
                off,
                g_end
            )); 
        }

        if (value == 0) {
            number = string(abi.encodePacked(
                a,
               on,
                b,
               on,
                c,
               on,
               d,
               on
            ));

            number = string(abi.encodePacked(
                number,
                e,
                on,
                f,
                on
            ));

            return string(abi.encodePacked(
                g_transform,
                seven_segment_2,
                number,
                g,
                off,
                g_end
            )); 
        }

        if (value == 1) {
            number = string(abi.encodePacked(
                a,
               off,
                b,
               on,
                c,
               on,
               d,
               off
            ));

            number = string(abi.encodePacked(
                number,
                e,
                off,
                f,
                off
            ));

            return string(abi.encodePacked(
                g_transform,
                seven_segment_2,
                number,
                g,
                off,
                g_end
            )); 
        }

        if (value == 2) {
            number = string(abi.encodePacked(
                a,
               on,
                b,
               on,
                c,
               off,
               d,
               on
            ));

            number = string(abi.encodePacked(
                number,
                e,
                on,
                f,
                off
            ));

            return string(abi.encodePacked(
                g_transform,
                seven_segment_2,
                number,
                g,
                on,
                g_end
            )); 
        }

        if (value == 3) {
            number = string(abi.encodePacked(
                a,
               on,
                b,
               on,
                c,
               on,
               d,
               on
            ));

            number = string(abi.encodePacked(
                number,
                e,
                off,
                f,
                off
            ));

            return string(abi.encodePacked(
                g_transform,
                seven_segment_2,
                number,
                g,
                on,
                g_end
            )); 
        }

        if (value == 4) {
            number = string(abi.encodePacked(
                a,
               off,
                b,
               on,
                c,
               on,
               d,
               off
            ));

            number = string(abi.encodePacked(
                number,
                e,
                off,
                f,
                on
            ));

            return string(abi.encodePacked(
                g_transform,
                seven_segment_2,
                number,
                g,
                on,
                g_end
            )); 
        }

        if (value == 5) {
            number = string(abi.encodePacked(
                a,
               on,
                b,
               off,
                c,
               on,
               d,
               on
            ));

            number = string(abi.encodePacked(
                number,
                e,
                off,
                f,
                on
            ));

            return string(abi.encodePacked(
                g_transform,
                seven_segment_2,
                number,
                g,
                on,
                g_end
            )); 
        }

        if (value == 6) {
            number = string(abi.encodePacked(
                a,
               on,
                b,
               off,
                c,
               on,
               d,
               on
            ));

            number = string(abi.encodePacked(
                number,
                e,
                on,
                f,
                on
            ));

            return string(abi.encodePacked(
                g_transform,
                seven_segment_2,
                number,
                g,
                on,
                g_end
            )); 
        }

        if (value == 7) {
            number = string(abi.encodePacked(
                a,
               on,
                b,
               on,
                c,
               on,
               d,
               off
            ));

            number = string(abi.encodePacked(
                number,
                e,
                off,
                f,
                off
            ));

            return string(abi.encodePacked(
                g_transform,
                seven_segment_2,
                number,
                g,
                off,
                g_end
            )); 
        }

        if (value == 8) {
            number = string(abi.encodePacked(
                a,
               on,
                b,
               on,
                c,
               on,
               d,
               on
            ));

            number = string(abi.encodePacked(
                number,
                e,
                on,
                f,
                on
            ));

            return string(abi.encodePacked(
                g_transform,
                seven_segment_2,
                number,
                g,
                on,
                g_end
            )); 
        }

        if (value == 9) {
            number = string(abi.encodePacked(
                a,
               on,
                b,
               on,
                c,
               on,
               d,
               off
            ));

            number = string(abi.encodePacked(
                number,
                e,
                off,
                f,
                on
            ));

            return string(abi.encodePacked(
                g_transform,
                seven_segment_2,
                number,
                g,
                on,
                g_end
            )); 
        }
    }

    function get3(uint256 value) internal pure returns (string memory number) {
        if (value > 9) {
            number = string(abi.encodePacked(
                a,
               off,
                b,
               off,
                c,
               off,
               d,
               off
            ));

            number = string(abi.encodePacked(
                number,
                e,
                off,
                f,
                off
            ));

            return string(abi.encodePacked(
                g_transform,
                seven_segment_3,
                number,
                g,
                off,
                g_end
            )); 
        }

        if (value == 0) {
            number = string(abi.encodePacked(
                a,
               on,
                b,
               on,
                c,
               on,
               d,
               on
            ));

            number = string(abi.encodePacked(
                number,
                e,
                on,
                f,
                on
            ));

            return string(abi.encodePacked(
                g_transform,
                seven_segment_3,
                number,
                g,
                off,
                g_end
            )); 
        }

        if (value == 1) {
            number = string(abi.encodePacked(
                a,
               off,
                b,
               on,
                c,
               on,
               d,
               off
            ));

            number = string(abi.encodePacked(
                number,
                e,
                off,
                f,
                off
            ));

            return string(abi.encodePacked(
                g_transform,
                seven_segment_3,
                number,
                g,
                off,
                g_end
            )); 
        }

        if (value == 2) {
            number = string(abi.encodePacked(
                a,
               on,
                b,
               on,
                c,
               off,
               d,
               on
            ));

            number = string(abi.encodePacked(
                number,
                e,
                on,
                f,
                off
            ));

            return string(abi.encodePacked(
                g_transform,
                seven_segment_3,
                number,
                g,
                on,
                g_end
            )); 
        }

        if (value == 3) {
            number = string(abi.encodePacked(
                a,
               on,
                b,
               on,
                c,
               on,
               d,
               on
            ));

            number = string(abi.encodePacked(
                number,
                e,
                off,
                f,
                off
            ));

            return string(abi.encodePacked(
                g_transform,
                seven_segment_3,
                number,
                g,
                on,
                g_end
            )); 
        }

        if (value == 4) {
            number = string(abi.encodePacked(
                a,
               off,
                b,
               on,
                c,
               on,
               d,
               off
            ));

            number = string(abi.encodePacked(
                number,
                e,
                off,
                f,
                on
            ));

            return string(abi.encodePacked(
                g_transform,
                seven_segment_3,
                number,
                g,
                on,
                g_end
            )); 
        }

        if (value == 5) {
            number = string(abi.encodePacked(
                a,
               on,
                b,
               off,
                c,
               on,
               d,
               on
            ));

            number = string(abi.encodePacked(
                number,
                e,
                off,
                f,
                on
            ));

            return string(abi.encodePacked(
                g_transform,
                seven_segment_3,
                number,
                g,
                on,
                g_end
            )); 
        }

        if (value == 6) {
            number = string(abi.encodePacked(
                a,
               on,
                b,
               off,
                c,
               on,
               d,
               on
            ));

            number = string(abi.encodePacked(
                number,
                e,
                on,
                f,
                on
            ));

            return string(abi.encodePacked(
                g_transform,
                seven_segment_3,
                number,
                g,
                on,
                g_end
            )); 
        }

        if (value == 7) {
            number = string(abi.encodePacked(
                a,
               on,
                b,
               on,
                c,
               on,
               d,
               off
            ));

            number = string(abi.encodePacked(
                number,
                e,
                off,
                f,
                off
            ));

            return string(abi.encodePacked(
                g_transform,
                seven_segment_3,
                number,
                g,
                off,
                g_end
            )); 
        }

        if (value == 8) {
            number = string(abi.encodePacked(
                a,
               on,
                b,
               on,
                c,
               on,
               d,
               on
            ));

            number = string(abi.encodePacked(
                number,
                e,
                on,
                f,
                on
            ));

            return string(abi.encodePacked(
                g_transform,
                seven_segment_3,
                number,
                g,
                on,
                g_end
            )); 
        }

        if (value == 9) {
            number = string(abi.encodePacked(
                a,
               on,
                b,
               on,
                c,
               on,
               d,
               off
            ));

            number = string(abi.encodePacked(
                number,
                e,
                off,
                f,
                on
            ));

            return string(abi.encodePacked(
                g_transform,
                seven_segment_3,
                number,
                g,
                on,
                g_end
            )); 
        }
    }
}

contract Callee {
    function getDay(uint value1, uint value2, uint value3) 
        external 
        pure 
        returns (string memory) 
    {
        return string(abi.encodePacked(
            RenderDays.get1(value1),
            RenderDays.get2(value2),
            RenderDays.get3(value3)
        ));
    }
}