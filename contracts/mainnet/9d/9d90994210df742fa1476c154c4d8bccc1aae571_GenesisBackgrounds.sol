/**
 *Submitted for verification at Etherscan.io on 2022-03-21
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract GenesisBackgrounds {
    function G_Background(uint32 traitId_) public pure returns (string[2] memory) {
        string memory _header = "iVBORw0KGgoAAAANSUhEUgAAACIAAAAiBAMAAADIaRbxAAAABGdBTUEAALGPC/xhBQAAAAFzUkdCAK7OHOkAAAAZdEVYdFNvZnR3YXJlAEFkb2JlIEltYWdlUmVhZHlxyWU8AAAAG1BMVE";
        if (traitId_ == 0) return  ["1" , string(abi.encodePacked(_header, "XQ/am7+ofU+7TJ/J7d+MbD+pXY+by0+3qx/3ASyLiCAAAALklEQVQoz2N0YUADTOgCDCxKhNUQI8JIJXOoBRiNqeMeqoWPIJXck0Ylc6jkHgA2bQGmh/4HAwAAAABJRU5ErkJggg=="))];
        if (traitId_ == 1) return  ["2" , string(abi.encodePacked(_header, "WV+pmp/ay0+7fG+Mh6+4Ce/KJw/3a8+b6H+owCjb93AAAAL0lEQVQoz2M0ZkADTOgCDCwuhNUQI8KoRCVzBKljDrX8RS3A2EGl8KGSv1ioFF8AwVICGvXM4TcAAAAASUVORK5CYII="))];
        if (traitId_ == 2) return  ["3" , string(abi.encodePacked(_header, "W0+9up/daH+sWe/NGV+svG+OG8+dx6+8Fw/771l7DHAAAALElEQVQoz2MMZUADTOgCDCyChNUQI0ItwEgl97AoUckcKrmHkVruCR1c/gIA7rUBdnWxIpkAAAAASUVORK5CYII="))];
        if (traitId_ == 3) return  ["4" , string(abi.encodePacked(_header, "V69Pue+Pyp+v3G9vi89/lw+P+V9vqH9fq0+PuE6LnaAAAAL0lEQVQoz2M0ZkADTOgCDCyChNUQI8LiQh1zGJWoZA61/BVKJXOo5B5qAUYq+QsAVOABtz6MXe8AAAAASUVORK5CYII="))];
        if (traitId_ == 4) return  ["5" , string(abi.encodePacked(_header, "WHu/q01Ptwsf/G3fh6tPuVw/q82Pmp0P2eyfzHB43xAAAAMElEQVQoz2M0ZkADTOgCDCxEqCFGhFGQOuawpFHJHGq55yx1zKEWYHShUnwpUcccAD6MAmJlKUIyAAAAAElFTkSuQmCC"))];
        if (traitId_ == 5) return  ["6" , string(abi.encodePacked(_header, "WMh/rIxvisqf23tPuZlfqinvyAevt2cP++vPlRD1K4AAAALklEQVQoz2MUZEADTOgCDCzlhNUQI8JoTB1zWN5TyZxB5h5qAcY0KvlLkDrmAAAUoAOHmKV/SwAAAABJRU5ErkJggg=="))];
        if (traitId_ == 6) return  ["7" , string(abi.encodePacked(_header, "XFh/rhxvjWqf3btPvLlfrRnvzBevu+cP/cvPnqX8JlAAAALklEQVQoz2MUZEADTOgCDCzlhNUQI8JoTB1zWN5TyZxB5h5qAcY0KvlLkDrmAAAUoAOHmKV/SwAAAABJRU5ErkJggg=="))];
        if (traitId_ == 7) return  ["8" , string(abi.encodePacked(_header, "X6h/X7evT5vPf/cPj9qfr6lfb8nvj4xvb7tPiHd1ddAAAALklEQVQoz2MsZ0ADTOgCDIxKhNUQI8KSRh1zGF2o5B5q+es9dcyhFmAUHFzhAwBE5QLI+iB+4QAAAABJRU5ErkJggg=="))];
        if (traitId_ == 8) return  ["9" , string(abi.encodePacked(_header, "X7erT9qdD8nsn4xt37tNT6lcP6h7v/cLH5vNiwiCG3AAAALUlEQVQoz2M0ZkADTOgCDCyhhNUQI8LoQiVzBKljDgu1zDEeXO6hFmAsp457ALKdAepHLCaaAAAAAElFTkSuQmCC"))];
        if (traitId_ == 9) return  ["10", string(abi.encodePacked(_header, "X/dnD9rKn4yMb6jIf6mZX7gHr8op77t7T5vryOgBnpAAAAL0lEQVQoz2NUYkADTOgCDCxphNUQI8LynjrmMApSyT2hVDLn3uAKHxYl6phDLQAA1XMEE0bDaa4AAAAASUVORK5CYII="))];
        if (traitId_ == 10) return ["11", string(abi.encodePacked(_header, "X6xYf/vnD44cb727T6y5X91qn53Lz80Z77wXqHV10dAAAAL0lEQVQoz2NUYkADTOgCDCwuhNUQI8JoTB1zWJQGmTlnqWMOtQBjB5XiS5A65gAARZYChB63YAgAAAAASUVORK5CYII="))];
        if (traitId_ == 11) return ["12", string(abi.encodePacked(_header, "X6/an1+of4+7T4/J72+Mb2+pX3+bz0+3r4/3A+w8iCAAAALklEQVQoz2N0YUADTOgCDCxKhNUQI8JIJXOoBRiNqeMeqoWPIJXck0Ylc6jkHgA2bQGmh/4HAwAAAABJRU5ErkJggg=="))];
        return ["",""];
    }
}