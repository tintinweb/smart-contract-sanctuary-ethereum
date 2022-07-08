// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
error YoureNotTheOwnerHomie();
contract RHGB
{
    constructor()
    {
        _Owner = msg.sender;
    }
    bool public HuntActive = false;
    bool public EasterEgg1_locked = false;
    bool public EasterEgg2_locked = false;
    address private _Owner;
    address public EasterEgg1_Winner;
    address public EasterEgg2_Winner;
    string public EasterEgg1_WinnerTwitter;
    string public EasterEgg2_WinnerTwitter;
    address[] public RRR;
    // enter your twitter handle!
    function EggMcMuffin(string memory _twitterHandle) external returns (string memory)
    {
        require(HuntActive, "loading...");
        require(!EasterEgg1_locked, string(abi.encodePacked(EasterEgg1_WinnerTwitter, " beat you to it!")));
        require(OINT(RRR[0]).balanceOf(msg.sender) > 0, "wait what? get a goodblock!");
        require(EasterEgg2_Winner != msg.sender, "lets share the love!");
        require(keccak256(bytes(EasterEgg2_WinnerTwitter)) != keccak256(bytes(_twitterHandle)), "same twitter handle?");
        EasterEgg1_WinnerTwitter = _twitterHandle;
        EasterEgg1_Winner = msg.sender;
        EasterEgg1_locked = true;
        return "You found the goodblocks easter egg 1!";
    }
    // enter your twitter handle!
    function realRecognizeReal(string memory _twitterHandle) external returns (string memory)
    {
        require(HuntActive, "loading...");
        require(!EasterEgg2_locked, string(abi.encodePacked(EasterEgg2_WinnerTwitter, " beat you to it!")));
        require(EasterEgg1_Winner != msg.sender, "lets share the love!");
        require(keccak256(bytes(EasterEgg1_WinnerTwitter)) != keccak256(bytes(_twitterHandle)), "same twitter handle?");
        bool o = true;
        for(uint256 i=0; i<RRR.length; i++)
        {
            if(OINT(RRR[i]).balanceOf(msg.sender) < 1)
            {
                o = false;
                break;
            }
        }
        require(o, "support some other great projects! ;)");
        EasterEgg2_WinnerTwitter = _twitterHandle;
        EasterEgg2_Winner = msg.sender;
        EasterEgg2_locked = true;
        return "you found the goodblocks easter egg 2!";
    }
    function setRRR(address _address, uint256 _index) external
    {
        if(msg.sender != _Owner) revert YoureNotTheOwnerHomie();
        if(_index >= RRR.length)
        {
            RRR.push(_address);
        } else
        {
            RRR[_index] = _address;
        }
    }
    function toggleHunt() external
    {
        if(msg.sender != _Owner) revert YoureNotTheOwnerHomie();
        HuntActive = !HuntActive;
    }
    function transferOwnership(address _newOwner) external 
    {
        if(msg.sender != _Owner) revert YoureNotTheOwnerHomie();
        _Owner = _newOwner;
    }
}
interface OINT
{
    function balanceOf(address _Owner) external view returns (uint256);
}