/**
 *Submitted for verification at Etherscan.io on 2022-03-21
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract BabyAccessories {
    string private constant _bodyHeader = "AAAABGdBTUEAALGPC/xhBQAAAAFzUkdCAK7OHOkAAAAZdEVYdFNvZnR3YXJlAEFkb2JlIEltYWdlUmVhZHlxyWU8AAAA";
    function B_Accessory(uint32 traitId_) public pure returns (string[2] memory) {
        if (traitId_ == 0 ) return ["AirPods Pro",          string(abi.encodePacked("iVBORw0KGgoAAAANSUhEUgAAACIAAAAiAgMAAABHKeNR", _bodyHeader, "CVBMVEVHcEz////m5uYK7NwXAAAAAXRSTlMAQObYZgAAABhJREFUGNNjYBiSIADOmgBnCcBZCgPrOACdhAERFdyo8wAAAABJRU5ErkJggg=="))];
        if (traitId_ == 1 ) return ["Green Bowtie",         string(abi.encodePacked("iVBORw0KGgoAAAANSUhEUgAAACIAAAAiBAMAAADIaRbx", _bodyHeader, "D1BMVEVHcEwAAAA6cAQzWQ4wUQ2e5K2CAAAAAXRSTlMAQObYZgAAAERJREFUKM9jYBgFIwcwCgrASQgQVlIEkkJgEipipCQgyKiEJCJipKSoJIwi4qxkaCRsjCziYgzU5WxsiGSXIJAUBNoFAEl5Bg9cuTCrAAAAAElFTkSuQmCC"))];
        if (traitId_ == 2 ) return ["Gold Piercing",        string(abi.encodePacked("iVBORw0KGgoAAAANSUhEUgAAACIAAAAiAgMAAABHKeNR", _bodyHeader, "CVBMVEVHcEwAAAD/2QD4CUMoAAAAAXRSTlMAQObYZgAAABVJREFUGNNjYBjWwAHGYJyAKUYrAABzcAESIeQazgAAAABJRU5ErkJggg=="))];
        if (traitId_ == 3 ) return ["Gold Chain",           string(abi.encodePacked("iVBORw0KGgoAAAANSUhEUgAAACIAAAAiAQMAAAAAiZmB", _bodyHeader, "BlBMVEVHcEz/2QBxSM7qAAAAAXRSTlMAQObYZgAAAC9JREFUCNdjYBhQoIBECoBJDjDJAiaZIYoawKQDmDQAK+AA0gwMbAwHgCTjf5hhAFV2A1bLpJ9NAAAAAElFTkSuQmCC"))];
        if (traitId_ == 4 ) return ["Snot",                 string(abi.encodePacked("iVBORw0KGgoAAAANSUhEUgAAACIAAAAiAgMAAABHKeNR", _bodyHeader, "DFBMVEVHcEx4mVaTxWKDrVpoSy33AAAAAXRSTlMAQObYZgAAABVJREFUGNNjYBhOwAHOOgBnNdDdFQC41AGBg8SM7QAAAABJRU5ErkJggg=="))];
        if (traitId_ == 5 ) return ["Blue Gum",             string(abi.encodePacked("iVBORw0KGgoAAAANSUhEUgAAACIAAAAiCAMAAAANmfvw", _bodyHeader, "NlBMVEVHcEyfzP+Yyf9grv8+jeJxtf////8gU4WFwP+OxP+v1f9Dlu6o0f+n0f+UyP9+vP+WyP9QpP+JFKynAAAAAXRSTlMAQObYZgAAAEhJREFUGBntwdkVgCAMRcEHBG/ibv/NWgH518OMpulfAOUox4oyRNx1QWM83T3qgoaw7h6xoyGsuftZ0BjW+hUog9mGcoA+6gUclQGi4iyJZQAAAABJRU5ErkJggg=="))];
        if (traitId_ == 6 ) return ["Red Bowtie",           string(abi.encodePacked("iVBORw0KGgoAAAANSUhEUgAAACIAAAAiBAMAAADIaRbx", _bodyHeader, "D1BMVEVHcEwAAACdGQV8IhRxHhKz65XXAAAAAXRSTlMAQObYZgAAAERJREFUKM9jYBgFIwcwCgrASQgQVlIEkkJgEipipCQgyKiEJCJipKSoJIwi4qxkaCRsjCziYgzU5WxsiGSXIJAUBNoFAEl5Bg9cuTCrAAAAAElFTkSuQmCC"))];
        if (traitId_ == 7 ) return ["Gold Earring",         string(abi.encodePacked("iVBORw0KGgoAAAANSUhEUgAAACIAAAAiAQMAAAAAiZmB", _bodyHeader, "BlBMVEVHcEz/2QBxSM7qAAAAAXRSTlMAQObYZgAAABdJREFUCNdjYBgMoAFEMCogSIYDZJgCAFqIAYOx+s3SAAAAAElFTkSuQmCC"))];
        if (traitId_ == 8 ) return ["Pink Gum",             string(abi.encodePacked("iVBORw0KGgoAAAANSUhEUgAAACIAAAAiCAMAAAANmfvw", _bodyHeader, "NlBMVEVHcEz/mOz/n+3/YOXoN8r/ceb///+JHHn/her/juv1PNb/r/H/p/D/lO3/fun/qO//UOD/luzHH5RsAAAAAXRSTlMAQObYZgAAAEhJREFUGBntwdkVgCAMRcEHBG/ibv/NWgH518OMpulfAOWo+4YyRDxlQWPc3T3Kgoaw7h5xoSGsuftR0RjW+hkog9mKcoA+6gUdXwGiiQu2GwAAAABJRU5ErkJggg=="))];
        if (traitId_ == 9 ) return ["Silver Piercing",      string(abi.encodePacked("iVBORw0KGgoAAAANSUhEUgAAACIAAAAiAgMAAABHKeNR", _bodyHeader, "CVBMVEVHcEwAAADA+/YkUvCMAAAAAXRSTlMAQObYZgAAABVJREFUGNNjYBjWwAHGYJyAKUYrAABzcAESIeQazgAAAABJRU5ErkJggg=="))];
        if (traitId_ == 10) return ["Mole",                 string(abi.encodePacked("iVBORw0KGgoAAAANSUhEUgAAACIAAAAiAQMAAAAAiZmB", _bodyHeader, "BlBMVEVHcExDJA1iryrTAAAAAXRSTlMAQObYZgAAAA9JREFUCB1jGCRAgYFyAAAJTAAh7FQYRQAAAABJRU5ErkJggg=="))];
        if (traitId_ == 11) return ["Orange Bib",           string(abi.encodePacked("iVBORw0KGgoAAAANSUhEUgAAACIAAAAiBAMAAADIaRbx", _bodyHeader, "LVBMVEVHcEzt7e31vpHi29voxq/m4uLpno/kjo/tqZDeu6XSx8fiwKnUysrhdXfnjn/8HVY5AAAAAXRSTlMAQObYZgAAADtJREFUKM9jYBgFIxlwYojMWgAiTyMEWEKDjYHA0AEhEiioBASCCBFXQaH0jIoyRREkEY2K9PS8S0ARAJ3mCqleS1jOAAAAAElFTkSuQmCC"))];
        if (traitId_ == 12) return ["Blue Bib",             string(abi.encodePacked("iVBORw0KGgoAAAANSUhEUgAAACIAAAAiBAMAAADIaRbx", _bodyHeader, "LVBMVEVHcEzt7e2RyPXb4uKv0eji5uaO5OOP2umQ1O2lyN7H0tKpy+LK1NR/2Od14d9bCOEmAAAAAXRSTlMAQObYZgAAADtJREFUKM9jYBgFIxlwYojMWgAiTyMEWEKDjYHA0AEhEiioBASCCBFXQaGyiox0RREkEY2MsrLaR0ARAJ7xCtYATdCmAAAAAElFTkSuQmCC"))];
        if (traitId_ == 13) return ["Green Bib",            string(abi.encodePacked("iVBORw0KGgoAAAANSUhEUgAAACIAAAAiBAMAAADIaRbx", _bodyHeader, "LVBMVEVHcEzt7e2R9afd4tuv6Lnj5uKV6Y+j5I6Q7ZSl3q7K0sep4rPM1MqI53+Q4XUUnm+OAAAAAXRSTlMAQObYZgAAADtJREFUKM9jYBgFIxlwYojMWgAiTyMEWEKDjYHA0AEhEiioBASCCBFXQaH0jIoyRREkEY2K9PTcR0ARAJ4hCri5YsP8AAAAAElFTkSuQmCC"))];
        if (traitId_ == 14) return ["Pink Bib",             string(abi.encodePacked("iVBORw0KGgoAAAANSUhEUgAAACIAAAAiBAMAAADIaRbx", _bodyHeader, "LVBMVEVHcEzt7e31kefg2+Lor+Pl4ubHjuTbj+nokO3epdrOx9Liqd3RytS8deHVf+c92OVzAAAAAXRSTlMAQObYZgAAADtJREFUKM9jYBgFIxlwYojMWgAiTyMEWEKDjYHA0AEhEiioBASCCBFXQaGyiox0RREkEY2MsrK6S0ARAJ62CscU5P/6AAAAAElFTkSuQmCC"))];
        if (traitId_ == 15) return ["Hidden",               string(abi.encodePacked("iVBORw0KGgoAAAANSUhEUgAAACIAAAAiAQMAAAAAiZmB", _bodyHeader, "A1BMVEVHcEyC+tLSAAAAAXRSTlMAQObYZgAAAAtJREFUCB1jGEYAAADMAAEGY11RAAAAAElFTkSuQmCC"))];
        return ["",""];
    }
}