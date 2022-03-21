/**
 *Submitted for verification at Etherscan.io on 2022-03-21
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract BabyEyes {
    string private constant _bodyHeader = "AAAABGdBTUEAALGPC/xhBQAAAAFzUkdCAK7OHOkAAAAZdEVYdFNvZnR3YXJlAEFkb2JlIEltYWdlUmVhZHlxyWU8AAAA";
    function B_Eyes(uint32 traitId_) public pure returns (string[2] memory) {
        if (traitId_ == 0 ) return ["Green Scouter",        string(abi.encodePacked("iVBORw0KGgoAAAANSUhEUgAAACIAAAAiBAMAAADIaRbx", _bodyHeader, "JFBMVEVHcEwB/xEAAAAAvQ3w//0+/07z9uY//UjAu7t7e3tC/0////94FCMIAAAAAnRSTlMAvcNDAgkAAAA3SURBVCjPY2AYcUCJgUHQWABJgClFgVG41LAJIaLmpMBoHkxAxGUDo3nowkmohgsKCjCMAlQAAPtwCNFm1/wXAAAAAElFTkSuQmCC"))];
        if (traitId_ == 1 ) return ["Red Scouter",          string(abi.encodePacked("iVBORw0KGgoAAAANSUhEUgAAACIAAAAiBAMAAADIaRbx", _bodyHeader, "JFBMVEVHcEz/AAAAAAC9AADw//37QkHz9ub8QDzAu7t7e3v/QkL///92ucYiAAAAAnRSTlMAvcNDAgkAAAA3SURBVCjPY2AYcUCJgUHQWABJgClFgVG41LAJIaLmpMBoHkxAxGUDo3nowkmohgsKCjCMAlQAAPtwCNFm1/wXAAAAAElFTkSuQmCC"))];
        if (traitId_ == 2 ) return ["Green Glasses",        string(abi.encodePacked("iVBORw0KGgoAAAANSUhEUgAAACIAAAAiBAMAAADIaRbx", _bodyHeader, "GFBMVEVHcEwAAABx4h0AAABUWVj///9VVlBZWVntwTSIAAAAAnRSTlMApkkmy+UAAABOSURBVCjPY2AY1oBJSUmBgUFJSQnOVxQ1FlJQMhUUgilRUgxOMVRSDjGEizComjkbKqg6I4kogkTUkEWYzFwKFdRcChEiYGsgFo4CZAAA43AKBHWXEQoAAAAASUVORK5CYII="))];
        if (traitId_ == 3 ) return ["Blue Glasses",         string(abi.encodePacked("iVBORw0KGgoAAAANSUhEUgAAACIAAAAiBAMAAADIaRbx", _bodyHeader, "GFBMVEVHcEwAAAAAqf8AAABUWVj///9VVlBZWVnBKyLfAAAAAnRSTlMApkkmy+UAAABOSURBVCjPY2AY1oBJSUmBgUFJSQnOVxQ1FlJQMhUUgilRUgxOMVRSDjGEizComjkbKqg6I4kogkTUkEWYzFwKFdRcChEiYGsgFo4CZAAA43AKBHWXEQoAAAAASUVORK5CYII="))];
        if (traitId_ == 4 ) return ["Red Glasses",          string(abi.encodePacked("iVBORw0KGgoAAAANSUhEUgAAACIAAAAiBAMAAADIaRbx", _bodyHeader, "GFBMVEVHcEwAAAD/AAAAAABUWVj///9VVlBZWVmov7BmAAAAAnRSTlMApkkmy+UAAABOSURBVCjPY2AY1oBJSUmBgUFJSQnOVxQ1FlJQMhUUgilRUgxOMVRSDjGEizComjkbKqg6I4kogkTUkEWYzFwKFdRcChEiYGsgFo4CZAAA43AKBHWXEQoAAAAASUVORK5CYII="))];
        if (traitId_ == 5 ) return ["Sleepy Eyes",          string(abi.encodePacked("iVBORw0KGgoAAAANSUhEUgAAACIAAAAiAQMAAAAAiZmB", _bodyHeader, "BlBMVEVHcEwAAACfKoRRAAAAAXRSTlMAQObYZgAAABRJREFUCNdjYKA5mDABRCYk0NwiAMA8AeE7g/FuAAAAAElFTkSuQmCC"))];
        if (traitId_ == 6 ) return ["Yellow Glasses",       string(abi.encodePacked("iVBORw0KGgoAAAANSUhEUgAAACIAAAAiBAMAAADIaRbx", _bodyHeader, "GFBMVEVHcEz/4QDhxwBjVwD////285v47o3/85zS0FggAAAAAnRSTlMAY6Io/doAAABYSURBVCjPY2AYToBJSYGBQUkJSURR0ImBSVBEAa5ASdBEUEHR2FEIpkJJSdjVUEk5xVAIYYxJsKGCmjOyiBtQRCUYWcQstFBBLbQQIQI0SQlkgQLDKEABAI8tCnRlcCK8AAAAAElFTkSuQmCC"))];
        if (traitId_ == 7 ) return ["Closed Eyes",          string(abi.encodePacked("iVBORw0KGgoAAAANSUhEUgAAACIAAAAiAQMAAAAAiZmB", _bodyHeader, "BlBMVEVHcEwAAACfKoRRAAAAAXRSTlMAQObYZgAAABBJREFUCB1joBd48ICB1gAArSwBwUQyqW0AAAAASUVORK5CYII="))];
        if (traitId_ == 8 ) return ["Eye Patch",            string(abi.encodePacked("iVBORw0KGgoAAAANSUhEUgAAACIAAAAiBAMAAADIaRbx", _bodyHeader, "D1BMVEVHcEwAAADw//3z9ub////BYGAmAAAAAXRSTlMAQObYZgAAACxJREFUKM9jYBhRgFEQBpAEgTwBRiMBNBFhRfwiQKMYhJUckE0XFGAYBZgAALwBAuiVDXD4AAAAAElFTkSuQmCC"))];
        if (traitId_ == 9 ) return ["Squinty Eyes",         string(abi.encodePacked("iVBORw0KGgoAAAANSUhEUgAAACIAAAAiAQMAAAAAiZmB", _bodyHeader, "BlBMVEVHcEwAAACfKoRRAAAAAXRSTlMAQObYZgAAABVJREFUCNdjYKAhSEgAkQINCDZNAQDYHAIR2NPMVQAAAABJRU5ErkJggg=="))];
        if (traitId_ == 10) return ["Happy Eyes",           string(abi.encodePacked("iVBORw0KGgoAAAANSUhEUgAAACIAAAAiAQMAAAAAiZmB", _bodyHeader, "BlBMVEVHcEwAAACfKoRRAAAAAXRSTlMAQObYZgAAABRJREFUCB1joCVISGAAggkTGOgDAMk8AeEgnEkWAAAAAElFTkSuQmCC"))];
        if (traitId_ == 11) return ["bEyes1",               string(abi.encodePacked("iVBORw0KGgoAAAANSUhEUgAAACIAAAAiBAMAAADIaRbx", _bodyHeader, "D1BMVEVHcEwAAADw//3z9ub////BYGAmAAAAAXRSTlMAQObYZgAAACNJREFUKM9jYBhxQBCK4YDRSACMEUBYUQCM8YooOYDxKCAEAE1XAqOUSEoaAAAAAElFTkSuQmCC"))];
        if (traitId_ == 12) return ["bEyes2",               string(abi.encodePacked("iVBORw0KGgoAAAANSUhEUgAAACIAAAAiBAMAAADIaRbx", _bodyHeader, "D1BMVEVHcEwAAADw//3z9ub////BYGAmAAAAAXRSTlMAQObYZgAAACVJREFUKM9jYBhxQBCK4YDRUACMEUBYUQCMkUSUHMAYn8gowA4Awg8DAxtB7gMAAAAASUVORK5CYII="))];
        if (traitId_ == 13) return ["bEyes3",               string(abi.encodePacked("iVBORw0KGgoAAAANSUhEUgAAACIAAAAiBAMAAADIaRbx", _bodyHeader, "D1BMVEVHcEwAAADw//3z9ub////BYGAmAAAAAXRSTlMAQObYZgAAACVJREFUKM9jYBhxQBCK4YBRUACMEUBY0AGMkUSUHMAYn8gowA4AvS8DA+A0PscAAAAASUVORK5CYII="))];
        if (traitId_ == 14) return ["bEyes4",               string(abi.encodePacked("iVBORw0KGgoAAAANSUhEUgAAACIAAAAiBAMAAADIaRbx", _bodyHeader, "D1BMVEVHcEwAAADw//3////z9uYqEDDUAAAAAXRSTlMAQObYZgAAACZJREFUKM9jYBhxQBCK4YBRSACMkZQIGYAxAogoGYAxPpFRgB0AAE0TAqcbtT1PAAAAAElFTkSuQmCC"))];
        if (traitId_ == 15) return ["bEyes5",               string(abi.encodePacked("iVBORw0KGgoAAAANSUhEUgAAACIAAAAiBAMAAADIaRbx", _bodyHeader, "D1BMVEVHcEwAAADw//3////z9uYqEDDUAAAAAXRSTlMAQObYZgAAACRJREFUKM9jYBhxQBCK4YDRSQCMkZQIGYAxPhERJQMwHgWEAAChdwLhXpbg8gAAAABJRU5ErkJggg=="))];
        if (traitId_ == 16) return ["bEyes6",               string(abi.encodePacked("iVBORw0KGgoAAAANSUhEUgAAACIAAAAiBAMAAADIaRbx", _bodyHeader, "D1BMVEVHcEwAAADw//3////z9uYqEDDUAAAAAXRSTlMAQObYZgAAACZJREFUKM9jYBhxQBCK4YDRSQCMEUBEyQCMkTQJGYAxPpFRgB0AAKbPAuEPAiXbAAAAAElFTkSuQmCC"))];
        if (traitId_ == 17) return ["bEyes7",               string(abi.encodePacked("iVBORw0KGgoAAAANSUhEUgAAACIAAAAiBAMAAADIaRbx", _bodyHeader, "D1BMVEVHcEwAAADz9ub////w//0w6hPyAAAAAXRSTlMAQObYZgAAACVJREFUKM9jYBhxQBCK4YBRRQCMEUDIxQCMkUQEDcAYn8gowA4Ap8MC5ezGbOYAAAAASUVORK5CYII="))];
        if (traitId_ == 18) return ["bEyes8",               string(abi.encodePacked("iVBORw0KGgoAAAANSUhEUgAAACIAAAAiBAMAAADIaRbx", _bodyHeader, "D1BMVEVHcEwAAADw//3z9ub////BYGAmAAAAAXRSTlMAQObYZgAAACVJREFUKM9jYBhxQBCK4YDRSACMEUBYyQGMkUQUBcAYn8gowA4AWx8Co6O/zsMAAAAASUVORK5CYII="))];
        if (traitId_ == 19) return ["bEyes9",               string(abi.encodePacked("iVBORw0KGgoAAAANSUhEUgAAACIAAAAiBAMAAADIaRbx", _bodyHeader, "D1BMVEVHcEwAAADz9ub////w//0w6hPyAAAAAXRSTlMAQObYZgAAACNJREFUKM9jYBhxQBCK4YBRRQCMEUBI0ACM8Yq4GIDxKCAEAJlrAuVh2+82AAAAAElFTkSuQmCC"))];
        return ["",""];
    }
}