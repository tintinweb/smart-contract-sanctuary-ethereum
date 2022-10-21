/**
 *Submitted for verification at Etherscan.io on 2022-10-20
*/

pragma solidity ^ 0.4.0;

// general utilities contract -- string ops, etc.
contract Utilities {
    // convert address to string (https://ethereum.stackexchange.com/a/8447)
    function toString(address x) constant internal returns (string) {
        bytes memory s = new bytes(40);
        for (uint i = 0; i < 20; i++) {
            byte b = byte(uint8(uint(x) / (2**(8*(19 - i)))));
            byte hi = byte(uint8(b) / 16);
            byte lo = byte(uint8(b) - 16 * uint8(hi));
            s[2*i] = byte2ascii(hi);
            s[2*i+1] = byte2ascii(lo);            
        }
        return string(s);
    }
    
    // convert address to 8char string (https://ethereum.stackexchange.com/a/8447)
    function toStringShort(address x) constant internal returns (string) {
        bytes memory s = new bytes(8);
        for (uint i = 0; i < 4; i++) {
            byte b = byte(uint8(uint(x) / (2**(8*(19 - i)))));
            byte hi = byte(uint8(b) / 16);
            byte lo = byte(uint8(b) - 16 * uint8(hi));
            s[2*i] = byte2ascii(hi);
            s[2*i+1] = byte2ascii(lo);            
        }
        return string(s);
    }

    // helper function to encode byte as (ascii https://ethereum.stackexchange.com/a/8447)
    function byte2ascii(byte b) constant internal returns (byte c) {
        if (b < 10) return byte(uint8(b) + 0x30);
        else return byte(uint8(b) + 0x57);
    }
    
    // convert uint to string
    function toString(uint x) constant internal returns(string) {
        return bytes32ToString(uintToBytes(x));
    }

    // concatenate two strings
    function strConcat(string _a, string _b) constant internal returns(string) {
        bytes memory _ba = bytes(_a);
        bytes memory _bb = bytes(_b);

        string memory ab = new string(_ba.length + _bb.length);
        bytes memory bab = bytes(ab);

        uint k = 0;
        for (uint i = 0; i < _ba.length; i++) bab[k++] = _ba[i];
        for (i = 0; i < _bb.length; i++) bab[k++] = _bb[i];

        return string(bab);
    }

    // 3 input concat
    function strConcat(string _a, string _b, string _c) constant internal returns(string) {
        return strConcat(_a, strConcat(_b, _c));
    }

    // 4 input concat
    function strConcat(string _a, string _b, string _c, string _d) constant internal returns(string) {
        return strConcat(_a, strConcat(_b, strConcat(_c, _d)));
    }
    
    // 5 input concat
    function strConcat(string _a, string _b, string _c, string _d, string _e) constant internal returns(string) {
        return strConcat(_a, strConcat(_b, strConcat(_c, strConcat(_e, _d))));
    }

    // MIT licensed, pipermerriam/ethereum-string-utils
    function uintToBytes(uint v) constant internal returns(bytes32 ret) {
        if (v == 0) {
            ret = '0';
        } else {
            while (v > 0) {
                ret = bytes32(uint(ret) / (2 ** 8));
                ret |= bytes32(((v % 10) + 48) * 2 ** (8 * 31));
                v /= 10;
            }
        }
        return ret;
    }

    // https://ethereum.stackexchange.com/a/2834
    function bytes32ToString(bytes32 x) constant internal returns(string) {
        bytes memory bytesString = new bytes(32);
        uint charCount = 0;
        for (uint j = 0; j < 32; j++) {
            byte char = byte(bytes32(uint(x) * 2 ** (8 * j)));
            if (char != 0) {
                bytesString[charCount] = char;
                charCount++;
            }
        }
        bytes memory bytesStringTrimmed = new bytes(charCount);
        for (j = 0; j < charCount; j++) {
            bytesStringTrimmed[j] = bytesString[j];
        }
        return string(bytesStringTrimmed);
    }
}

contract BoardAdmin is Utilities {
    address internal adminAccount;
    string internal boardTopic;
    uint256 internal postCount;
    string constant VERSION = "\xF0\x9F\xA6\x8C Antler v0.1.0a";

    // easy admin-only goodness
    modifier onlyAdmin {
        require(msg.sender == adminAccount);
        _;
    }

    // init board and set defaults
    function BoardAdmin() {
        adminAccount = msg.sender;
        boardTopic = "[topic not set]";
        postCount = 0;
    }

    // erase the entire thread
    function zAdminOnly_deleteBoard() onlyAdmin {
        selfdestruct(adminAccount);
    }


    // set the board's topic
    function zAdminOnly_setTopic(string newBoardTopic) onlyAdmin {
        boardTopic = newBoardTopic;
    }
}

contract Antler is BoardAdmin {
    string[] internal posts;

    function xMeta_boardInformation() public constant returns(string) {
        string memory openingInfo;
        
        openingInfo = strConcat("Welcome to ", VERSION, "! ");
        openingInfo = strConcat(openingInfo, "Topic is: ", boardTopic, " ");
        openingInfo = strConcat(openingInfo, "(", toString(postCount), " posts)");

        return openingInfo;
    }
    
    function xMeta_whoIsAdmin() public constant returns(string) {
        return strConcat("Admin is ", toString(adminAccount));
    }

    function post(string postText) public returns(string) {
        string memory postHeader;
        string memory completePost;

        // slap it all together
        postHeader = strConcat("#", toString(postCount), "/0x", toStringShort(msg.sender));
        completePost = strConcat(postHeader, ": ", postText);
        posts.push(completePost);
        postCount++;

        return completePost;
    }

    function read(uint postID) public constant returns(string) {
        if(postCount == 0){
            return "No posts yet!";
        }
        
        if(postID >= postCount){
            return "No such post!";
        }

        return posts[postID];
    }
    
    function readMostRecent() public constant returns(string) {
        if(postCount == 0){
            return "No posts yet!";
        }

        return posts[postCount - 1];
    }

    
    function readAll() public constant returns(string) {
        string memory postList;
        
        
        if(posts.length == 0){
            return "No posts yet!";
        }

        for (uint256 i = 0; i < postCount; i++) {
            if (i == 0) {
                postList = posts[i];
            } else {
                postList = strConcat(postList, "\n======ENDPOST======\n\n", posts[i]);
            }
        }

        return postList;
    }
}