/**
 *Submitted for verification at Etherscan.io on 2022-03-21
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract BabyMouths {
    string private constant _bodyHeader = "AAAABGdBTUEAALGPC/xhBQAAAAFzUkdCAK7OHOkAAAAZdEVYdFNvZnR3YXJlAEFkb2JlIEltYWdlUmVhZHlxyWU8AAAA";
    function B_Mouth(uint32 traitId_) public pure returns (string[2] memory) {
        if (traitId_ == 0 ) return ["Pink Pacifier",        string(abi.encodePacked("iVBORw0KGgoAAAANSUhEUgAAACIAAAAiBAMAAADIaRbx", _bodyHeader, "IVBMVEVHcEyeYob22+rif7ngx9XGap/r0d+aYIOUXn/WbavMa6MdVr72AAAAAXRSTlMAQObYZgAAAC1JREFUKM9jYBgFQwIwCgqiiUhONhZAFelSUkYTaQsNQhNhKRdCN9olgbZOBwBa0wRgqCWU3gAAAABJRU5ErkJggg=="))];
        if (traitId_ == 1 ) return ["Green Pacifier",       string(abi.encodePacked("iVBORw0KGgoAAAANSUhEUgAAACIAAAAiBAMAAADIaRbx", _bodyHeader, "IVBMVEVHcExRk2zX9eRx35/B3c1awIXM6dlMiGRPj2hd0Y1bx4imtoOoAAAAAXRSTlMAQObYZgAAAC1JREFUKM9jYBgFQwIwCgqiiUhONhZAFalSUkYTKQsNQhNh6RBCN9olgbZOBwBQpQRRF7BrtgAAAABJRU5ErkJggg=="))];
        if (traitId_ == 2 ) return ["Fangs",                string(abi.encodePacked("iVBORw0KGgoAAAANSUhEUgAAACIAAAAiAgMAAABHKeNR", _bodyHeader, "CVBMVEVHcEwAAAD///8W1S+BAAAAAXRSTlMAQObYZgAAABlJREFUGNNjYBiBgDE0FMZMSYGxBASoZTwAijYBlB8vivUAAAAASUVORK5CYII="))];
        if (traitId_ == 3 ) return ["Wide Open Mouth",      string(abi.encodePacked("iVBORw0KGgoAAAANSUhEUgAAACIAAAAiBAMAAADIaRbx", _bodyHeader, "D1BMVEVHcEwAAACyWJ5KAQ3////tffuDAAAAAXRSTlMAQObYZgAAACZJREFUKM9jYBgFgxEIogswugigiQgbG6KJCCkpoutSEiBoMs0BAO8rAXcsCw3fAAAAAElFTkSuQmCC"))];
        if (traitId_ == 4 ) return ["Bucktooth Up",         string(abi.encodePacked("iVBORw0KGgoAAAANSUhEUgAAACIAAAAiAgMAAABHKeNR", _bodyHeader, "CVBMVEVHcEwAAAD///8W1S+BAAAAAXRSTlMAQObYZgAAABdJREFUGNNjYBg5QADOSoExGEMdqG8PAF2FAQuqj6CsAAAAAElFTkSuQmCC"))];
        if (traitId_ == 5 ) return ["Bucktooth Down",       string(abi.encodePacked("iVBORw0KGgoAAAANSUhEUgAAACIAAAAiAgMAAABHKeNR", _bodyHeader, "CVBMVEVHcEwAAAD///8W1S+BAAAAAXRSTlMAQObYZgAAABZJREFUGNNjYBiJIDQAxpKEi7FQzXQARvYAw1q+5VgAAAAASUVORK5CYII="))];
        if (traitId_ == 6 ) return ["Tongue Down",          string(abi.encodePacked("iVBORw0KGgoAAAANSUhEUgAAACIAAAAiAgMAAABHKeNR", _bodyHeader, "CVBMVEVHcEwAAAC6SkpCPX1UAAAAAXRSTlMAQObYZgAAABdJREFUGNNjYBiJIDQAxpJygLFYqWY6AFxUAQWS1nLMAAAAAElFTkSuQmCC"))];
        if (traitId_ == 7 ) return ["Tongue Up",            string(abi.encodePacked("iVBORw0KGgoAAAANSUhEUgAAACIAAAAiAgMAAABHKeNR", _bodyHeader, "CVBMVEVHcEwAAAC6SkpCPX1UAAAAAXRSTlMAQObYZgAAABdJREFUGNNjYBjugBXOknKAsUIDaGkjAGQkAQUPp1sRAAAAAElFTkSuQmCC"))];
        if (traitId_ == 8 ) return ["Open Mouth",           string(abi.encodePacked("iVBORw0KGgoAAAANSUhEUgAAACIAAAAiAgMAAABHKeNR", _bodyHeader, "DFBMVEVHcEwAAACyWJ5KAQ0T7zk9AAAAAXRSTlMAQObYZgAAABhJREFUGNNjYBg5gBXOkneAsaQcMGUpBQBEuADEvaMY0AAAAABJRU5ErkJggg=="))];
        if (traitId_ == 9 ) return ["Hidden",               string(abi.encodePacked("iVBORw0KGgoAAAANSUhEUgAAACIAAAAiAQMAAAAAiZmB", _bodyHeader, "A1BMVEVHcEyC+tLSAAAAAXRSTlMAQObYZgAAAAtJREFUCB1jGEYAAADMAAEGY11RAAAAAElFTkSuQmCC"))];
        if (traitId_ == 10) return ["bMouth1",              string(abi.encodePacked("iVBORw0KGgoAAAANSUhEUgAAACIAAAAiAQMAAAAAiZmB", _bodyHeader, "BlBMVEVHcEwAAACfKoRRAAAAAXRSTlMAQObYZgAAABNJREFUCNdjYBhEQABM8h8gUzsAMhMA4PUMH50AAAAASUVORK5CYII="))];
        if (traitId_ == 11) return ["bMouth2",              string(abi.encodePacked("iVBORw0KGgoAAAANSUhEUgAAACIAAAAiAQMAAAAAiZmB", _bodyHeader, "BlBMVEVHcEwAAACfKoRRAAAAAXRSTlMAQObYZgAAABNJREFUCNdjYBh0gP8AiBQgXSMAMVMA4BfdR9EAAAAASUVORK5CYII="))];
        if (traitId_ == 12) return ["bMouth3",              string(abi.encodePacked("iVBORw0KGgoAAAANSUhEUgAAACIAAAAiAQMAAAAAiZmB", _bodyHeader, "BlBMVEVHcEwAAACfKoRRAAAAAXRSTlMAQObYZgAAAA9JREFUCNdjYBh0gJlcjQABdwAEvoBbnQAAAABJRU5ErkJggg=="))];
        if (traitId_ == 13) return ["bMouth4",              string(abi.encodePacked("iVBORw0KGgoAAAANSUhEUgAAACIAAAAiAQMAAAAAiZmB", _bodyHeader, "BlBMVEVHcEwAAACfKoRRAAAAAXRSTlMAQObYZgAAABBJREFUCNdjYBh0gL2BTI0AHlsAiErrPQoAAAAASUVORK5CYII="))];
        if (traitId_ == 14) return ["bMouth5",              string(abi.encodePacked("iVBORw0KGgoAAAANSUhEUgAAACIAAAAiAQMAAAAAiZmB", _bodyHeader, "BlBMVEVHcEwAAACfKoRRAAAAAXRSTlMAQObYZgAAABBJREFUCNdjYBh0gP8AmRoBLiMA0C6fqOkAAAAASUVORK5CYII="))];
        return ["",""];
    }
}