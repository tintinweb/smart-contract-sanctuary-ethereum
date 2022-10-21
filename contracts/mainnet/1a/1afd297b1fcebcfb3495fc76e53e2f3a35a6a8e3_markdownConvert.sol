/**
 *Submitted for verification at Etherscan.io on 2022-10-20
*/

pragma solidity ^0.4.0;

contract mortal {
    /* Define variable owner of the type address*/
    address owner;

    /* this function is executed at initialization and sets the owner of the contract */
    function mortal() { owner = msg.sender; }

    /* Function to recover the funds on the contract */
    function kill() { if (msg.sender == owner) selfdestruct(owner); }
}

contract markdownConvert is mortal {
    // concatenate two strings
    function concat(string _a, string _b) internal returns (string){
        bytes memory _ba = bytes(_a);
        bytes memory _bb = bytes(_b);

        string memory ab = new string(_ba.length + _bb.length);
        bytes memory bab = bytes(ab);
        
        uint k = 0;
        for (uint i = 0; i < _ba.length; i++) bab[k++] = _ba[i];
        for (i = 0; i < _bb.length; i++) bab[k++] = _bb[i];

        return string(bab);
    }
    
    // concatenate a byte to a string
    function concatByte(string _a, byte _b) internal returns (string){
        bytes memory aBytes = bytes(_a);

        string memory expandedA = new string(aBytes.length + 1);
        bytes memory finalBytes = bytes(expandedA);
        
        uint k = 0;
        for (uint i = 0; i < aBytes.length; i++) finalBytes[k++] = aBytes[i];
        finalBytes[k] = _b;

        return string(finalBytes);
    }
    
    // const definitions
    string constant boldSpan = '<span style="font-weight: bold;">';
    string constant underlineSpan = '<span style="text-decoration: underline;">';
    string constant italicSpan = '<span style="font-style: italic;">';
    string constant spanClose = '</span>';
    
    string constant asteriskStr = '*';
    string constant underscoreStr = '_';
    string constant forwardslashStr = '/';
    string constant backslashStr = '\\';
    
    byte constant asterisk = bytes(asteriskStr)[0];
    byte constant underscore = bytes(underscoreStr)[0];
    byte constant forwardslash = bytes(forwardslashStr)[0];
    byte constant backslash = bytes(backslashStr)[0];
    
    /* main function */
    function send(string inString) constant returns (string) {
        bytes memory inBytes = bytes(inString);
        string memory returnString;
        
        bool openBold = false;
        bool openUnderline = false;
        bool openItalic = false;
        bool escaped = false;
        
        for (uint i = 0; i < inBytes.length; i++){
            // check for escaped
            if(escaped){
                // write the char and keep moving
                returnString = concatByte(returnString, inBytes[i]);
                escaped = false;
                continue;
            }
            
            // continue with scanning for format chars
            if(inBytes[i] == asterisk){
                if(!openBold){
                    // this is an opening tag
                    returnString = concat(returnString, boldSpan);
                } else {
                    // already have one open; close it
                    returnString = concat(returnString, spanClose);
                }
                
                // toggle tag open status whatever we did
                openBold = !openBold;
            } else if (inBytes[i] == underscore){
                if(!openUnderline){
                    returnString = concat(returnString, underlineSpan);
                } else {
                    returnString = concat(returnString, spanClose);
                }
                
                openUnderline = !openUnderline;
            } else if (inBytes[i] == forwardslash){
                if(!openItalic){
                    returnString = concat(returnString, italicSpan);
                } else {
                    returnString = concat(returnString, spanClose);
                }
                
                openItalic = !openItalic;
            } else if (inBytes[i] == backslash){
                // the next char is escaed; set flag to print as literal
                escaped = true;
            } else {
                returnString = concatByte(returnString, inBytes[i]);
            }
        }
        
        // close up remaining tags if something is left open
        if(openBold){
            returnString = concat(returnString, spanClose);
        }
        
        if(openUnderline){
            returnString = concat(returnString, spanClose);
        }
        
        if(openItalic){
            returnString = concat(returnString, spanClose);
        }
        
        return returnString;
    }
    
    // help
    function help() constant returns (string) {
        return "This is a simple markdown->HTML converter (e.g. *bold*, _underline_, /italics/). Use backslash to force literal char (e.g. \\*asterisk\\*)";
    }
}