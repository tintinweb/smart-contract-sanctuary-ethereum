/**
 *Submitted for verification at Etherscan.io on 2022-11-10
*/

// File: @opengsn\contracts\src\interfaces\IRelayRecipient.sol

// SPDX-License-Identifier: MIT
pragma solidity >=0.6.0;

/**
 * a contract must implement this interface in order to support relayed transaction.
 * It is better to inherit the BaseRelayRecipient as its implementation.
 */
abstract contract IRelayRecipient {

    /**
     * return if the forwarder is trusted to forward relayed transactions to us.
     * the forwarder is required to verify the sender's signature, and verify
     * the call is not a replay.
     */
    function isTrustedForwarder(address forwarder) public virtual view returns(bool);

    /**
     * return the sender of this call.
     * if the call came through our trusted forwarder, then the real sender is appended as the last 20 bytes
     * of the msg.data.
     * otherwise, return `msg.sender`
     * should be used in the contract anywhere instead of msg.sender
     */
    function _msgSender() internal virtual view returns (address);

    /**
     * return the msg.data of this call.
     * if the call came through our trusted forwarder, then the real sender was appended as the last 20 bytes
     * of the msg.data - so this method will strip those 20 bytes off.
     * otherwise (if the call was made directly and not through the forwarder), return `msg.data`
     * should be used in the contract instead of msg.data, where this difference matters.
     */
    function _msgData() internal virtual view returns (bytes calldata);

    function versionRecipient() external virtual view returns (string memory);
}

// File: @opengsn\contracts\src\BaseRelayRecipient.sol

// solhint-disable no-inline-assembly
pragma solidity >=0.6.9;

/**
 * A base contract to be inherited by any contract that want to receive relayed transactions
 * A subclass must use "_msgSender()" instead of "msg.sender"
 */
abstract contract BaseRelayRecipient is IRelayRecipient {

    /*
     * Forwarder singleton we accept calls from
     */
    address private _trustedForwarder;

    function trustedForwarder() public virtual view returns (address){
        return _trustedForwarder;
    }

    function _setTrustedForwarder(address _forwarder) internal {
        _trustedForwarder = _forwarder;
    }

    function isTrustedForwarder(address forwarder) public virtual override view returns(bool) {
        return forwarder == _trustedForwarder;
    }

    /**
     * return the sender of this call.
     * if the call came through our trusted forwarder, return the original sender.
     * otherwise, return `msg.sender`.
     * should be used in the contract anywhere instead of msg.sender
     */
    function _msgSender() internal override virtual view returns (address ret) {
        if (msg.data.length >= 20 && isTrustedForwarder(msg.sender)) {
            // At this point we know that the sender is a trusted forwarder,
            // so we trust that the last bytes of msg.data are the verified sender address.
            // extract sender address from the end of msg.data
            assembly {
                ret := shr(96,calldataload(sub(calldatasize(),20)))
            }
        } else {
            ret = msg.sender;
        }
    }

    /**
     * return the msg.data of this call.
     * if the call came through our trusted forwarder, then the real sender was appended as the last 20 bytes
     * of the msg.data - so this method will strip those 20 bytes off.
     * otherwise (if the call was made directly and not through the forwarder), return `msg.data`
     * should be used in the contract instead of msg.data, where this difference matters.
     */
    function _msgData() internal override virtual view returns (bytes calldata ret) {
        if (msg.data.length >= 20 && isTrustedForwarder(msg.sender)) {
            return msg.data[0:msg.data.length-20];
        } else {
            return msg.data;
        }
    }
}

// File: contracts\tip.sol

pragma solidity ^0.8.14;
pragma experimental ABIEncoderV2;
contract Tip is BaseRelayRecipient {
    address public owner;
    uint private SeigniorageRatio;

    //繧ｳ繝ｳ繝・Φ繝・′邂｡逅・＠縺ｦ縺・ｋ謚輔￡驫ｭ
    mapping(string => uint256) private _Tip;
    //繧ｳ繝ｳ繝・Φ繝・′邂｡逅・＠縺ｦ縺・ｋ闡嶺ｽ懈ｨｩ驕募渚諠・ｱ
    mapping(string => bool) private _Copyrightinfringement;
    //繧ｳ繝ｳ繝・Φ繝ФRI縺檎ｴ舌▼縺・※縺・ｋ繧｢繝峨Ξ繧ｹ
    mapping(string => address) private _originowners;
    //謚慕ｨｿ閠・′邂｡逅・＠縺ｦ縺・ｋ繧ｳ繝ｳ繝・Φ繝・焚
    mapping(address => string[]) private _contentsURI;
    //uri逋ｻ骭ｲ譎ゅ・index
    mapping(string => uint) private _indexLocal;
    mapping(string => uint) private _indexGlobal;
    //縺薙・繧ｳ繝ｳ繝医Λ繧ｯ繝医↓邏舌▼縺代＆繧後◆繧ｳ繝ｳ繝・Φ繝・
    string[] private ContentsList; 
    //迚｢迯・｡後Θ繝ｼ繧ｶ繝ｼ・医◎縺ｮ繝ｦ繝ｼ繧ｶ繝ｼ縺檎ｮ｡逅・☆繧九☆縺ｹ縺ｦ縺ｮ繧ｳ繝ｳ繝・Φ繝・・謚輔￡驫ｭ繧貞女縺大叙繧後↑縺上☆繧具ｼ・
    mapping(address => bool) private _Prison;

    string public override versionRecipient = "2.2.0";

    constructor() {
        owner = msg.sender;
        setSeigniorage(30);
    }
/*
    function _msgSender() internal view override(Context, BaseRelayRecipient) returns (address sender) {
        sender = BaseRelayRecipient._msgSender();
    }

    function _msgData() internal view override(Context, BaseRelayRecipient) returns (bytes memory) {
        return BaseRelayRecipient._msgData();
    }
*/
    function setForwarder(address forwarder_) public {
        _setTrustedForwarder(forwarder_);
    }

    modifier onlyOwner {
        require(
            owner == _msgSender(),
            "Only owner can call this function."
        );
        _;
    }

	//繧ｳ繝ｳ繝・Φ繝・・繧ｪ繝ｼ繝翫・
    function isOwner(string memory uri) public view returns (address) {
	    return _originowners[uri];
    }

	//繧ｳ繝ｳ繝医Λ繧ｯ繝医↓貅懊∪縺｣縺檸th
    function amount() public view onlyOwner returns (uint) {
	    return (payable(address(this))).balance;
    }

    function _exists(string memory uri) internal view returns (bool) {
        return _originowners[uri] != address(0);
    }

    //謚輔￡驫ｭ逕ｨ繧ｳ繝ｳ繝・Φ繝・匳骭ｲ・・PFS 繝輔ぃ繧､繝ｫ繝上ャ繧ｷ繝･・・
    function mint(string memory uri) public {
        require(_exists(uri)==false);
        ContentsList.push(uri);
        _Tip[uri] = 0;
        _Copyrightinfringement[uri] = false;
        _originowners[uri] = _msgSender();
        _contentsURI[_msgSender()].push(uri);
        _indexLocal[uri] = _contentsURI[_msgSender()].length-1;
        _indexGlobal[uri] = ContentsList.length-1;
    }

    function getContentsList(uint n) public view returns(string memory,bool) {
        require(ContentsList.length > n);
        return (ContentsList[n],_Copyrightinfringement[ContentsList[n]]);
   }

    function isContentsList() public view returns(uint256) {
        return ContentsList.length;
    }

    function setSeigniorage(uint p) public onlyOwner {
        SeigniorageRatio = 100/p;
    }

    function Compare(string memory a, string memory b) pure internal returns (bool) {
        if(bytes(a).length != bytes(b).length) {
            return false;
        } else {
            return keccak256(abi.encodePacked(a)) == keccak256(abi.encodePacked(b));
        }
    }

    //繧ｳ繝ｳ繝医Λ繧ｯ繝医↓謚輔￡驫ｭ繧定ｲｯ繧√※縺翫￥
    function throwTips(string memory uri) public payable {
        require(_exists(uri)==true);
        uint256 s = msg.value / SeigniorageRatio;
        _Tip[uri] += (msg.value - s);
        payable(owner).transfer(s);
    }

    //謖・ｮ壹い繝峨Ξ繧ｹ繧堤屮迯・｡後↓縺吶ｋ
    function goPrison(address ac) public onlyOwner {
        _Prison[ac] = true;
    }

    //謖・ｮ壹い繝峨Ξ繧ｹ繧堤屮迯・°繧芽ｧ｣謾ｾ縺吶ｋ
    function exitPrison(address ac) public onlyOwner{
        delete _Prison[ac];
    }

    //繧ｳ繝ｳ繝・Φ繝・が繝ｼ繝翫・繝医・繧ｿ繝ｫ縺ｮ謚輔￡驫ｭ鬘阪ｒ蜿門ｾ励☆繧・闡嶺ｽ懈ｨｩ驕募渚蝣ｱ蜻翫′縺ゅｋ繧ｳ繝ｳ繝・Φ繝・・髯､螟・
    function TotalBalanceOf() public view returns(uint){
        uint v = 0;    
        if(_Prison[_msgSender()])return 0;
        for(uint i = 0 ;i < _contentsURI[_msgSender()].length;i++){
            if(!_Copyrightinfringement[_contentsURI[_msgSender()][i]]){
                v += _Tip[_contentsURI[_msgSender()][i]];
            }
        }
        return v;
   }
    
    //闡嶺ｽ懈ｨｩ・域園譛画ｨｩ・蛾＆蜿榊ｱ蜻・謚慕ｨｿ閠・↓繧医ｋwithdoraw繧帝仆豁｢縺吶ｋ
    function CopyrightInfringement(string memory uri) public {
        address ad = _originowners[uri];
        require(ad!=_msgSender());
        require(_exists(uri)==true);
        _Copyrightinfringement[uri] = true;
    }
    //闡嶺ｽ懈ｨｩ・域園譛画ｨｩ・蛾＆蜿榊ｱ蜻翫・隗｣髯､讖溯・
    function CopyrightInfringementCancellation(string memory uri) public onlyOwner{
        require(_exists(uri)==true);
        _Copyrightinfringement[uri] = false;
    }

    //繧ｳ繝ｳ繝・Φ繝・→繧｢繝峨Ξ繧ｹ縺ｨ縺ｮ邏舌▼縺代ｒ隗｣髯､縺吶ｋ
    function contentscancel(string memory uri) public {
        require(_exists(uri)==true);
        require((_originowners[uri]==_msgSender())||(owner==_msgSender()));

        delete _Tip[uri];
        delete _Copyrightinfringement[uri];
        delete _contentsURI[_originowners[uri]][_indexLocal[uri]];
        delete _originowners[uri];
        delete _indexLocal[uri];
        delete ContentsList[_indexGlobal[uri]];
        delete _indexGlobal[uri];
    }

    function changeOwner(string memory uri,address cowner) public onlyOwner{
        require(_exists(uri)==true);
        require((_originowners[uri]!=cowner) || (msg.sender==owner));
        delete _contentsURI[_originowners[uri]][_indexLocal[uri]];
        _originowners[uri] = cowner;
        _contentsURI[cowner].push(uri);
        _indexLocal[uri] = _contentsURI[cowner].length;
    }

    //蠑輔″蜃ｺ縺励◆eth縺ｮ蠕悟ｧ区忰
    function _withdrawafter() internal {
        for(uint i = 0 ;i < _contentsURI[_msgSender()].length;i++){
            if(!_Copyrightinfringement[_contentsURI[_msgSender()][i]]){
                _Tip[_contentsURI[_msgSender()][i]] = 0;            
            }
        }
    }

	//繧ｳ繝ｳ繝医Λ繧ｯ繝医↓貅懊∪縺｣縺檸th縺ｮ蠑輔″蜃ｺ縺・
    function withdraw() public {
        require(TotalBalanceOf() > 0);
        require(TotalBalanceOf() <= (payable(address(this))).balance);
	    payable(_msgSender()).transfer(TotalBalanceOf());
	    _withdrawafter();
    }
}