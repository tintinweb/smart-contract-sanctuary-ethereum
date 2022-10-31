/**
 *Submitted for verification at Etherscan.io on 2022-10-31
*/

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

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

contract SvgData is Ownable {
   // string[5] private _backColor = ["#C7C8CF", "#DCC4BE", "#4E7187", "#8C5851", "#8972B1"];
    string[34] lookup = [
            '0', '10', '20', '30', '40', '50', '60', '70', 
            '80', '90', '100', '110', '120', '130', '140', '150', 
            '160', '170', '180', '190', '200', '210', '220', '230', 
            '240', '250', '260', '270', '280', '290', '300', '310',
            '320', '330' 
    ];
   string[187] colors = [
    "C7C8CF","DCC4BE","4E7187","8C5851","8972B1","640D0D","FFD926","47484C","911A1A","000000","FFFAFC","E22626",
    "FCFCFC","25395A","131414","E7DAD9","281C09","414040","2B4884","999999","37383B","A4A5A9","690A45","BA7609",
    "497E49","921919","727B46","493E7A","8C075B","33312E","534128","CAC9C3","89E8AD","35363C","474040","85A16F",
    "204988","8D92A6","38393A","BB961B","F3F3F4","93395E","598FEE","BE6871","486962","FCF7EB","5D8AA6","FFFFFF",
    "F9F9F9","FFFBF0","D50905","FFF7FA","086F9D","FFF4EC","170005","564548","D95347","FAE0D4","232323","E7E76B",
    "3EB8B4","8A9F74","08673F","231919","87D7B4","2081A5","AD3884","C32210","4D924B","57AD51","396239","345290",
    "325AAB","2D3E61","982A71","61204A","A41C0C","79160B","A66E2C","432916","3B3030","44331D","F0F0F0","3B8AFD",
    "FC3232","6A4124","A46807","C95FA2","51360C","6CC1C0","534C00","D50201","FEF78D","FEDA24","26314A","3D301E",
    "2C1D17","E9473F","C23A33","2E6C62","4C4C4C","373838","493C29","6D512B","27B242","7200C7","716E6D","685E51",
    "007CA5","8F9FA8","855113","DB6089","EDEDED","C9C9C9","8B8B8B","2F3139","AD1F60","A18E8D","091440","C5B3B2",
    "442206","6A3916","835533","C38323","7F592A","A07D4F","B29F85","D4B386","9E6F39","CA9E69","4390A4","295662",
    "1E383F","427380","D2FAFA","84BBBC","A9DEDF","627156","EB3223","736660","675742","A48C6F","762957","C86637",
    "6F8492","A3D7D8","801E59","5E378A","B7AA98","442E1E","43A257","4267B9","FFF68E","E55900","005D00","003559",
    "FE2C00","7E5627","303D70","F1F1E8","FF8DBE","FFF100","A32075","711010","665F5E","41230E","794B06","9F3073",
    "4F4883","4E83A3","8E92A4","AFBC8F","DD9871","CE3072","8D2F73","3D4883","252423","232427","E7D292","CD7161",
    "407FA1","6789A3","357AA1","729482","363636","4E4E4E","404248"
    ];
    bytes[] private _element;
    bytes[] private _fskin;
    bytes[] private _fcloth;
    bytes[] private _fearring;
    bytes[] private _fglass;
    bytes[] private _fhair;
    bytes[] private _fneck;
    bytes[] private _fsmoke;
    bytes[] private _mskin;
    bytes[] private _mbeard;
    bytes[] private _mcloth;
    bytes[] private _mearring;
    bytes[] private _mglass;
    bytes[] private _mhair;
    bytes[] private _mneck;
    bytes[] private _msmoke;
    //address private _generContract;

    function addComponent(uint tag, bytes memory item) public onlyOwner {
        if (1 == tag) {
            _fskin.push(item);
        }else if (2 == tag) {
            _fcloth.push(item);
        }else if (3 == tag) {
            _fearring.push(item);
        }else if (4 == tag) {
            _fglass.push(item);
        }else if (5 == tag) {
            _fhair.push(item);
        }else if (6 == tag) {
            _fneck.push(item);
        }else if (7 == tag) {
            _fsmoke.push(item);
        }else if (8 == tag) {  //男
            _mskin.push(item);
        }else if (9 == tag) {
            _mcloth.push(item);
        }else if (10 == tag) {
            _mglass.push(item);
        }else if (11 == tag) {
            _mhair.push(item);
        }else if (12 == tag) {
            _mneck.push(item);
        }else if (13 == tag) {
            _msmoke.push(item);
        }else if (14 == tag) {
            _mearring.push(item);
        }else if (15 == tag) {
            _mbeard.push(item);
        }else if (16 == tag) {
            _element.push(item);
        }
    }

    function changeTagInfo(uint256 tag, uint256 pos, bytes memory item) public onlyOwner {
        if (1 == tag) {
            _fskin[pos] = item;
        }else if (2 == tag) {
            _fcloth[pos] = item;
        }else if (3 == tag) {
            _fearring[pos] = item;
        }else if (4 == tag) {
            _fglass[pos] = item;
        }else if (5 == tag) {
            _fhair[pos] = item;
        }else if (6 == tag) {
            _fneck[pos] = item;
        }else if (7 == tag) {
            _fsmoke[pos] = item;
        }else if (8 == tag) {  //男
            _mskin[pos] = item;
        }else if (9 == tag) {
            _mcloth[pos] = item;
        }else if (10 == tag) {
            _mglass[pos] = item;
        }else if (11 == tag) {
            _mhair[pos] = item;
        }else if (12 == tag) {
            _mneck[pos] = item;
        }else if (13 == tag) {
            _msmoke[pos] = item;
        }else if (14 == tag) {
            _mearring[pos] = item;
        }else if (15 == tag) {
            _mbeard[pos] = item;
        }else if (16 == tag) {
            _element[pos] = item;
        }
    }

    // function setGenerContract(address generAddr) public onlyOwner {
    //     _generContract = generAddr;
    // }

    function getComonent(uint tag, uint pos) public view returns(bytes memory) {
        //require(msg.sender==_generContract, "do not have permission.");
        if (1 == tag) {
            return _fskin[pos];
        }else if (2 == tag) {
            return _fcloth[pos];
        }else if (3 == tag) {
            return _fearring[pos];
        }else if (4 == tag) {
            return _fglass[pos];
        }else if (5 == tag) {
            return _fhair[pos];
        }else if (6 == tag) {
            return _fneck[pos];
        }else if (7 == tag) {
            return _fsmoke[pos];
        }else if (8 == tag) {  //男
            return _mskin[pos];
        }else if (9 == tag) {
            return _mcloth[pos];
        }else if (10 == tag) {
            return _mglass[pos];
        }else if (11 == tag) {
            return _mhair[pos];
        }else if (12 == tag) {
            return _mneck[pos];
        }else if (13 == tag) {
            return _msmoke[pos];
        }else if (14 == tag) {
            return _mearring[pos];
        }else if (15 == tag) {
            return _mbeard[pos];
        }else if (16 == tag) {
            return _element[pos];
        }else {
            return "";
        }
    }

    function getTagLength(uint tag) public view returns(uint) {
        if (1 == tag) {
            return _fskin.length;
        }else if (2 == tag) {
            return _fcloth.length;
        }else if (3 == tag) {
            return _fearring.length;
        }else if (4 == tag) {
            return _fglass.length;
        }else if (5 == tag) {
            return _fhair.length;
        }else if (6 == tag) {
            return _fneck.length;
        }else if (7 == tag) {
            return _fsmoke.length;
        }else if (8 == tag) {  //男
            return _mskin.length;
        }else if (9 == tag) {
            return _mcloth.length;
        }else if (10 == tag) {
            return _mglass.length;
        }else if (11 == tag) {
            return _mhair.length;
        }else if (12 == tag) {
            return _mneck.length;
        }else if (13 == tag) {
            return _msmoke.length;
        }else if (14 == tag) {
            return _mearring.length;
        }else if (15 == tag) {
            return _mbeard.length;
        }else if (16 == tag) {
            return _element.length;
        }else {
            return 0;
        }
    }

    function getStrokeByTag(uint256 tag, uint256 pos) public view returns(string memory) {
        string memory info = transByte2Rects(getComonent(tag, pos));
        return getStroke(info);
    }

    function transByte2Rects(bytes memory rectList) public view returns(string memory) {
        uint256 length = rectList.length/5;
        if (rectList.length%5>0) {length += 1;}

        string memory chunk = "";
        for (uint i = 0; i < length; ++i) {
            if (rectList.length-i*5 < 5) {break;}
            uint8 x = uint8(rectList[i*5]);
            uint8 y = uint8(rectList[i*5+1]);
            uint8 width = uint8(rectList[i*5+2]);
            uint8 height = uint8(rectList[i*5+3]);
            uint8 colorIndex = uint8(rectList[i*5+4]);
            string[5] memory buffer;
            buffer[0] = lookup[x];
            buffer[1] = lookup[y];
            buffer[2] = lookup[width];
            buffer[3] = lookup[height];
            buffer[4] = colors[colorIndex];
            chunk = string(
                abi.encodePacked(
                    chunk,
                    '<rect width="', buffer[2], '" height="', buffer[3], '" x="', buffer[0], '" y="', buffer[1], '" fill="#', buffer[4], '" />'
                )
            );
        }
        return chunk;
    }

    function getBackground(string memory color) public pure returns(string memory) {
        string memory output = '<g id="svg_1" fill-rule="evenodd" fill="none"><rect height="330" width="330" y="0" x="0" fill="#';
        output = string(abi.encodePacked(output, color, '"/></g>'));
        return output;
    }

    function getStroke(string memory info) public pure returns(string memory) {
        string memory output = '<g fill-rule="evenodd" fill="none">';
        output = string(abi.encodePacked(output, info, '</g>'));
        return output;
    }
}