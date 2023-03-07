// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import "./ERC721A.sol";
import "./Ownable.sol";
import "./Utilities.sol";
import "./Segments.sol";
import "./IERC4906.sol";

contract UltimateCurrency is ERC721A, Ownable, IERC4906 {
    
    event CountdownExtended(uint _finalBlock);

    uint public price = 3000000000000000; //.003 eth
    bool public isCombinable = false;
    uint public finalMintingBlock;

    SVGPrefix public _prefix;

    mapping(uint => uint) newValues;
    mapping(uint => uint) baseColors;
    mapping(address => uint) freeMints;

    constructor(address _address) ERC721A("Ultimate Currency", "TIME") {
        _prefix = SVGPrefix(_address);        
    }

    function mint(uint quantity) public payable {
        require(msg.value >= quantity * price, "not enough eth");
        handleMint(msg.sender, quantity);
    }

    function freeMint(uint quantity) public {
        require(quantity <= freeMints[msg.sender], "not enough free mints");
        handleMint(msg.sender, quantity);
        freeMints[msg.sender] -= quantity;
    }

    function handleMint(address recipient, uint quantity) internal {
        uint supply = _totalMinted();
        if (supply >= 5000) {
            require(utils.secondsRemaining(finalMintingBlock) > 0, "mint is closed");
            if (supply < 8000 && (supply + quantity) >= 8000) {
                finalMintingBlock = block.timestamp + 24 hours;
                emit CountdownExtended(finalMintingBlock);
            }
        } else if (supply + quantity >= 5000) {
            finalMintingBlock = block.timestamp + 24 hours;
            emit CountdownExtended(finalMintingBlock);
        }
        _mint(recipient, quantity);
    }

    function combine(uint[] memory tokens) public {
        require(isCombinable, "combining not active");
        uint256 sum;
        for (uint i = 0; i < tokens.length; i++) {
            require(ownerOf(tokens[i]) == msg.sender, "must own all tokens");
            sum = sum + getValue(tokens[i]);
        }
        if (sum > 315359999999) {
            revert("sum must be 9999:52:0:23:59:59 or less");
        }
        for (uint i = 1; i < tokens.length; i++) {
            _burn(tokens[i]);
            newValues[tokens[i]] = 0;
            baseColors[tokens[i]] = 0;
            emit MetadataUpdate(tokens[i]);
        }

        // Why was 6 afraid of 7? Because 7 8 9!
        newValues[tokens[0]] = sum;
        baseColors[tokens[0]] = utils.random(tokens[0], 1, 4);
        emit MetadataUpdate(tokens[0]);
    }

    function getValue(uint256 tokenId) public view returns (uint) {
        if (!_exists(tokenId)) {
            return 0;
        } else if (newValues[tokenId] > 0) {
            return newValues[tokenId];
        } else {
            return utils.initValue(tokenId);
        }
    }

    function tokenURI(uint256 tokenId) public view virtual override(ERC721A, IERC721A) returns (string memory) {
        bool burned;
        uint256 value;

        if (newValues[tokenId] > 0) {
            value = newValues[tokenId];
            burned = false;
        } else if (newValues[tokenId] == 0 && !_exists(tokenId)) {
            value = 0;
            burned = true;
        } else {
            if(tokenId <= 3) {
                //value = (tokenId < 2? 3153600000: 315360000);
                if(tokenId == 1) {
                    value = 31536000000;
                } else if(tokenId == 2) {
                    value = 3153600000;
                } else {
                    value = 315360000;
                }
            } else {
                value = utils.initValue(tokenId);
            }
            burned = false;
        }

        return segments.getMetadata(tokenId, value, baseColors[tokenId], burned, _prefix.prefixTxt());
    }

    function _startTokenId() internal view virtual override returns (uint256) {
        return 1;
    }

    function getMinutesRemaining() public view returns (uint) {
        return utils.minutesRemaining(finalMintingBlock);
    }

    function mintCount() public view returns (uint) {
        return _totalMinted();
    }

    function toggleCombinable() public onlyOwner {
        isCombinable = !isCombinable;
    }

    function withdraw() external onlyOwner {
        require(payable(msg.sender).send(address(this).balance));
    }

    function freeMintBalance(address addy) public view returns (uint) {
        return freeMints[addy];
    }

    function addFreeMints(address[] calldata addresses, uint quantity) public onlyOwner {
        for (uint i = 0; i < addresses.length; i++) {
            freeMints[addresses[i]] = quantity;
        }
    }

    function mint4Owner(uint quantity) public onlyOwner {
        handleMint(msg.sender, quantity);
    }
}


contract SVGPrefix {

    constructor() {

    }

    function prefixTxt() external pure returns (bytes memory) {
        
        return '<svg xmlns="http://www.w3.org/2000/svg" xmlns:xlink="http://www.w3.org/1999/xlink" viewBox="0 0 600 600"><defs><linearGradient id="_grad1" x1="124.8" y1="228.27" x2="124.8" y2="356.23" gradientTransform="matrix(1, 0, 0, 1, 0, 0)" gradientUnits="userSpaceOnUse"><stop offset="0" stop-color="#ffca3f"/><stop offset=".1" stop-color="#ca7c22"/><stop offset=".19" stop-color="#fddb7a"/><stop offset=".42" stop-color="#ffad45"/><stop offset=".55" stop-color="#a95f0d"/><stop offset=".66" stop-color="#ffad45"/><stop offset=".79" stop-color="#ffff9b"/><stop offset=".87" stop-color="#ffed7b"/><stop offset="1" stop-color="#ffca3f"/></linearGradient><linearGradient id="_grad2" y1="197.25" y2="357.47" xlink:href="#_grad1"/></defs><rect width="600" height="600" fill="white"/><path d="M540,431.58c0,10.18-8.22,18.42-18.36,18.42H78.36c-10.14,0-18.36-8.24-18.36-18.42V168.42c0-10.18,8.22-18.42,18.36-18.42h443.28c10.14,0,18.36,8.24,18.36,18.42V431.58Z" style="fill-rule:evenodd;"/><path d="M106.35,178.63c-.23-.8-.53-1.62-.8-2.07-.4-.67-.65-.85-2.02-.85h-2.5v12.17c0,1.95,.2,2.22,2.57,2.37v.7h-7.27v-.7c2.32-.15,2.52-.4,2.52-2.37v-12.17h-2.27c-1.37,0-1.77,.15-2.2,.9-.3,.5-.5,1.1-.82,2.02h-.75c.15-1.52,.3-3.1,.38-4.5h.57c.38,.6,.65,.57,1.35,.57h9.9c.7,0,.9-.1,1.27-.57h.6c0,1.17,.1,2.97,.22,4.42l-.75,.08Z" fill="white"/><path d="M107.88,190.95v-.7c1.57-.15,1.75-.27,1.75-1.97v-5.15c0-1.55-.08-1.65-1.58-1.9v-.6c1.3-.23,2.47-.55,3.55-1v8.65c0,1.7,.18,1.82,1.8,1.97v.7h-5.52Zm2.6-13.77c-.7,0-1.33-.62-1.33-1.32,0-.8,.62-1.38,1.35-1.38s1.28,.58,1.28,1.38c0,.7-.58,1.32-1.3,1.32Z" fill="white"/><path d="M128.4,190.95v-.7c1.47-.15,1.65-.25,1.65-2v-4.17c0-1.77-.6-2.9-2.15-2.9-.95,0-1.83,.52-2.77,1.3,.02,.3,.08,.6,.08,1.08v4.85c0,1.57,.22,1.7,1.6,1.85v.7h-5.35v-.7c1.55-.15,1.78-.25,1.78-1.9v-4.3c0-1.85-.58-2.87-2.1-2.87-1,0-1.97,.67-2.75,1.3v5.87c0,1.65,.18,1.75,1.6,1.9v.7h-5.37v-.7c1.65-.15,1.8-.25,1.8-1.9v-5.17c0-1.6-.1-1.7-1.5-1.95v-.62c1.17-.17,2.35-.5,3.47-1v2.02c.53-.4,1.05-.82,1.85-1.3,.62-.4,1.17-.65,1.97-.65,1.2,0,2.22,.75,2.72,2.05,.7-.55,1.35-.98,1.97-1.4,.55-.35,1.25-.65,1.97-.65,1.95,0,3.15,1.4,3.15,3.85v4.82c0,1.67,.15,1.75,1.57,1.9v.7h-5.2Z" fill="white"/><path d="M144.17,188.83c-1.6,2-3.35,2.42-4.15,2.42-3.05,0-4.9-2.5-4.9-5.37,0-1.7,.6-3.27,1.62-4.37,1.05-1.17,2.42-1.82,3.72-1.82,2.17,0,3.82,1.87,3.82,3.87-.02,.5-.1,.72-.5,.82-.5,.1-3.7,.32-6.67,.42-.08,3.35,1.97,4.72,3.75,4.72,1.02,0,1.97-.42,2.9-1.27l.4,.57Zm-4.3-8.2c-1.15,0-2.27,1.07-2.62,3.1,1.4,0,2.8,0,4.27-.08,.45,0,.6-.12,.6-.5,.02-1.32-.85-2.52-2.25-2.52Z" fill="white"/><path d="M166.92,186.96c-.35,1.2-1,3-1.38,3.77-.72,.15-2.67,.6-4.57,.6-5.97,0-9.02-3.97-9.02-8.35,0-5.1,3.87-8.62,9.47-8.62,2.15,0,3.9,.45,4.72,.58,.1,1.12,.27,2.62,.47,3.87l-.78,.17c-.5-1.67-1.1-2.7-2.37-3.22-.65-.3-1.67-.48-2.62-.48-4.12,0-6.3,3.05-6.3,7.17,0,4.82,2.5,7.92,6.55,7.92,2.55,0,3.8-1.17,5.07-3.67l.75,.25Z" fill="white"/><path d="M177.05,191.25c-.38,0-.92-.2-1.17-.47-.32-.33-.47-.67-.6-1.12-1,.67-2.22,1.6-3,1.6-1.77,0-3.05-1.47-3.05-3.07,0-1.22,.67-2.02,2.05-2.5,1.52-.52,3.4-1.17,3.95-1.62v-.5c0-1.77-.9-2.8-2.2-2.8-.58,0-.92,.28-1.17,.58-.28,.35-.45,.9-.67,1.62-.12,.4-.35,.57-.73,.57-.47,0-1.1-.5-1.1-1.1,0-.35,.33-.65,.83-1,.72-.52,2.17-1.45,3.6-1.75,.75,0,1.53,.23,2.1,.68,.88,.75,1.28,1.6,1.28,2.9v4.82c0,1.15,.42,1.5,.87,1.5,.3,0,.62-.12,.9-.27l.25,.7-2.12,1.25Zm-1.82-6.32c-.55,.27-1.75,.8-2.32,1.05-.95,.42-1.53,.9-1.53,1.82,0,1.32,1,1.92,1.8,1.92,.65,0,1.55-.4,2.05-.9v-3.9Z" fill="white"/><path d="M185.97,190.95h-5.75v-.7c1.57-.15,1.72-.27,1.72-1.9v-5.2c0-1.65-.1-1.72-1.55-1.9v-.62c1.22-.2,2.35-.5,3.52-1.02v2.75c.88-1.3,1.92-2.67,3.17-2.67,.92,0,1.45,.58,1.45,1.2,0,.58-.4,1.12-.85,1.38-.25,.15-.45,.12-.65-.05-.38-.37-.67-.62-1.12-.62-.53,0-1.45,.77-2,2.05v4.7c0,1.65,.12,1.77,2.05,1.92v.7Z" fill="white"/><path d="M201.47,190.33c-.53,.1-2.4,.4-3.87,.92v-1.62c-.45,.27-1.1,.62-1.55,.9-1,.57-1.67,.72-1.97,.72-2,0-4.65-2-4.65-5.5s3.05-6.07,6.47-6.07c.35,0,1.17,.05,1.7,.27v-3.67c0-1.6-.17-1.65-1.95-1.8v-.65c1.25-.18,3-.52,3.92-.85v15.07c0,1.3,.17,1.47,1.1,1.52l.8,.05v.7Zm-3.87-8.4c-.58-.87-1.65-1.27-2.62-1.27-1.2,0-3.32,.8-3.32,4.4,0,3.02,1.88,4.62,3.47,4.65,.9,0,1.87-.45,2.47-.9v-6.87Z" fill="white"/><path d="M507.39,267.29c-.11,7.26-2.86,13.31-8.37,18.08-.75,.65-1.79,.57-2.42-.16-.59-.69-.52-1.72,.22-2.36,2.01-1.73,3.68-3.74,4.91-6.1,3.87-7.38,2.92-16.21-2.46-22.57-.74-.88-1.6-1.66-2.44-2.45-.73-.68-.84-1.69-.22-2.42,.62-.71,1.66-.77,2.42-.12,4.63,4,7.37,9.02,8.21,15.08,.07,.47,.12,.95,.14,1.43,.02,.52,0,1.05,0,1.57Z" fill="white"/><path d="M499.74,267.92c-.12,4.81-2.18,9.33-6.29,12.89-.81,.7-1.86,.62-2.53-.16-.64-.74-.55-1.81,.24-2.5,2.15-1.86,3.72-4.11,4.47-6.85,1.51-5.59,.13-10.42-4-14.47-.15-.15-.32-.29-.48-.43-.75-.67-.85-1.75-.23-2.48,.66-.77,1.74-.85,2.53-.18,1.87,1.59,3.35,3.47,4.44,5.67,1.23,2.49,1.84,5.13,1.85,8.51Z" fill="white"/><path d="M486.91,275.48c-.7,0-1.32-.42-1.58-1.08-.26-.66-.09-1.39,.47-1.88,.82-.72,1.48-1.56,1.91-2.57,1.17-2.76,.44-5.81-1.88-7.87-.55-.49-.75-1.1-.54-1.8,.21-.68,.69-1.07,1.39-1.17,.49-.07,.93,.07,1.31,.39,4.25,3.52,4.85,10,1.31,14.24-.4,.48-.85,.93-1.34,1.33-.28,.23-.68,.34-1.02,.5l-.04-.09Z" fill="white"/><path d="M101.94,241.92h45.72c5.04,0,9.14,4.1,9.14,9.14v32.44c0,5.05-4.1,9.14-9.14,9.14h-45.71c-5.05,0-9.14-4.1-9.14-9.14v-32.43c0-5.05,4.1-9.14,9.14-9.14Z" style="fill:url(#_grad1);"/><path d="M156.8,257.9v-1.17h-11.72v-14.81h-1.17v14.81h-9.5c-1.25-3.97-4.75-6.9-9.02-7.3v-7.51h-1.17v7.43c-4.63,.08-8.5,3.17-9.82,7.38h-8.63v-14.81h-1.17v14.81h-11.8v1.17h11.8v16.59h-11.8v1.17h11.8v16.97h1.17v-16.97h8.38c1.06,4.62,5.15,8.08,10.06,8.17v8.8h1.17v-8.88c4.56-.43,8.27-3.73,9.27-8.09h9.25v16.97h1.17v-16.97h11.72v-1.17h-6.99v-16.59h6.99Zm-42.82,16.59h-8.21v-16.59h8.29c-.12,.64-.2,1.29-.2,1.96,0,2.46,.87,4.83,2.47,6.73-1.6,1.91-2.47,4.27-2.47,6.73,0,.4,.08,.78,.12,1.17Zm10.41,8.19c-5.16,0-9.36-4.2-9.36-9.36,0-2.33,.89-4.58,2.51-6.33l.36-.4-.36-.4c-1.62-1.75-2.51-4-2.51-6.33,0-5.16,4.2-9.36,9.36-9.36s9.36,4.2,9.36,9.36c0,2.34-.89,4.58-2.51,6.33l-.37,.4,.37,.4c1.62,1.75,2.51,4,2.51,6.33,0,5.16-4.2,9.36-9.36,9.36Zm24.24-8.19h-13.82c.04-.39,.12-.77,.12-1.17,0-2.46-.87-4.82-2.47-6.73,1.6-1.9,2.47-4.27,2.47-6.73,0-.67-.08-1.32-.2-1.96h13.9v16.59Z" style="fill:url(#_grad2); mix-blend-mode:multiply;"/><path id="p01" d="M110.21,332.41l1.93,1.93-1.93,1.93h-12.9l-1.93-1.93,1.93-1.93h12.9Z" fill="white" fill-opacity="0.05"/><path id="p02" d="M92.8,336.93l1.93-1.93,1.93,1.93v12.9l-1.93,1.93-1.93-1.93v-12.9Z" fill="white" fill-opacity="0.05"/><path id="p03" d="M110.86,336.93l1.93-1.93,1.93,1.93v12.9l-1.93,1.93-1.93-1.93v-12.9Z" fill="white" fill-opacity="0.05"/><path id="p04" d="M110.21,350.47l1.93,1.93-1.93,1.93h-12.9l-1.93-1.93,1.93-1.93h12.9Z" fill="white" fill-opacity="0.05"/><path id="p05" d="M92.8,354.98l1.93-1.93,1.93,1.93v12.9l-1.93,1.93-1.93-1.93v-12.9Z" fill="white" fill-opacity="0.05"/><path id="p06" d="M110.86,354.98l1.93-1.93,1.93,1.93v12.9l-1.93,1.93-1.93-1.93v-12.9Z" fill="white" fill-opacity="0.05"/><path id="p07" d="M110.21,368.52l1.93,1.93-1.93,1.93h-12.9l-1.93-1.93,1.93-1.93h12.9Z" fill="white" fill-opacity="0.05"/><path id="p11" d="M136.13,332.41l1.93,1.93-1.93,1.93h-12.9l-1.93-1.93,1.93-1.93h12.9Z" fill="white" fill-opacity="0.05"/><path id="p12" d="M118.73,336.93l1.93-1.93,1.93,1.93v12.9l-1.93,1.93-1.93-1.93v-12.9Z" fill="white" fill-opacity="0.05"/><path id="p13" d="M136.78,336.93l1.93-1.93,1.93,1.93v12.9l-1.93,1.93-1.93-1.93v-12.9Z" fill="white" fill-opacity="0.05"/><path id="p14" d="M136.13,350.47l1.93,1.93-1.93,1.93h-12.9l-1.93-1.93,1.93-1.93h12.9Z" fill="white" fill-opacity="0.05"/><path id="p15" d="M118.73,354.98l1.93-1.93,1.93,1.93v12.9l-1.93,1.93-1.93-1.93v-12.9Z" fill="white" fill-opacity="0.05"/><path id="p16" d="M136.78,354.98l1.93-1.93,1.93,1.93v12.9l-1.93,1.93-1.93-1.93v-12.9Z" fill="white" fill-opacity="0.05"/><path id="p17" d="M136.13,368.52l1.93,1.93-1.93,1.93h-12.9l-1.93-1.93,1.93-1.93h12.9Z" fill="white" fill-opacity="0.05"/> <path id="p21" d="M162.06,332.41l1.93,1.93-1.93,1.93h-12.9l-1.93-1.93,1.93-1.93h12.9Z" fill="white" fill-opacity="0.05"/><path id="p22" d="M144.65,336.93l1.93-1.93,1.93,1.93v12.9l-1.93,1.93-1.93-1.93v-12.9Z" fill="white" fill-opacity="0.05"/><path id="p23" d="M162.7,336.93l1.93-1.93,1.93,1.93v12.9l-1.93,1.93-1.93-1.93v-12.9Z" fill="white" fill-opacity="0.05"/><path id="p24" d="M162.06,350.47l1.93,1.93-1.93,1.93h-12.9l-1.93-1.93,1.93-1.93h12.9Z" fill="white" fill-opacity="0.05"/><path id="p25" d="M144.65,354.98l1.93-1.93,1.93,1.93v12.9l-1.93,1.93-1.93-1.93v-12.9Z" fill="white" fill-opacity="0.05"/><path id="p26" d="M162.7,354.98l1.93-1.93,1.93,1.93v12.9l-1.93,1.93-1.93-1.93v-12.9Z" fill="white" fill-opacity="0.05"/><path id="p27" d="M162.06,368.52l1.93,1.93-1.93,1.93h-12.9l-1.93-1.93,1.93-1.93h12.9Z" fill="white" fill-opacity="0.05"/><path id="p31" d="M187.98,332.41l1.93,1.93-1.93,1.93h-12.9l-1.93-1.93,1.93-1.93h12.9Z" fill="white" fill-opacity="0.05"/><path id="p32" d="M170.57,336.93l1.93-1.93,1.93,1.93v12.9l-1.93,1.93-1.93-1.93v-12.9Z" fill="white" fill-opacity="0.05"/><path id="p33" d="M188.62,336.93l1.93-1.93,1.93,1.93v12.9l-1.93,1.93-1.93-1.93v-12.9Z" fill="white" fill-opacity="0.05"/><path id="p34" d="M187.98,350.47l1.93,1.93-1.93,1.93h-12.9l-1.93-1.93,1.93-1.93h12.9Z" fill="white" fill-opacity="0.05"/><path id="p35" d="M170.57,354.98l1.93-1.93,1.93,1.93v12.9l-1.93,1.93-1.93-1.93v-12.9Z" fill="white" fill-opacity="0.05"/><path id="p36" d="M188.62,354.98l1.93-1.93,1.93,1.93v12.9l-1.93,1.93-1.93-1.93v-12.9Z" fill="white" fill-opacity="0.05"/><path id="p37" d="M187.98,368.52l1.93,1.93-1.93,1.93h-12.9l-1.93-1.93,1.93-1.93h12.9Z" fill="white" fill-opacity="0.05"/><path id="p41" d="M230.16,332.41l1.93,1.93-1.93,1.93h-12.9l-1.93-1.93,1.93-1.93h12.9Z" fill="white" fill-opacity="0.05"/><path id="p42" d="M212.75,336.93l1.93-1.93,1.93,1.93v12.9l-1.93,1.93-1.93-1.93v-12.9Z" fill="white" fill-opacity="0.05"/><path id="p43" d="M230.81,336.93l1.93-1.93,1.93,1.93v12.9l-1.93,1.93-1.93-1.93v-12.9Z" fill="white" fill-opacity="0.05"/><path id="p44" d="M230.16,350.47l1.93,1.93-1.93,1.93h-12.9l-1.93-1.93,1.93-1.93h12.9Z" fill="white" fill-opacity="0.05"/><path id="p45" d="M212.75,354.98l1.93-1.93,1.93,1.93v12.9l-1.93,1.93-1.93-1.93v-12.9Z" fill="white" fill-opacity="0.05"/><path id="p46" d="M230.81,354.98l1.93-1.93,1.93,1.93v12.9l-1.93,1.93-1.93-1.93v-12.9Z" fill="white" fill-opacity="0.05"/><path id="p47" d="M230.16,368.52l1.93,1.93-1.93,1.93h-12.9l-1.93-1.93,1.93-1.93h12.9Z" fill="white" fill-opacity="0.05"/><path id="p51" d="M256.08,332.41l1.93,1.93-1.93,1.93h-12.9l-1.93-1.93,1.93-1.93h12.9Z" fill="white" fill-opacity="0.05"/><path id="p52" d="M238.67,336.93l1.93-1.93,1.93,1.93v12.9l-1.93,1.93-1.93-1.93v-12.9Z" fill="white" fill-opacity="0.05"/><path id="p53" d="M256.73,336.93l1.93-1.93,1.93,1.93v12.9l-1.93,1.93-1.93-1.93v-12.9Z" fill="white" fill-opacity="0.05"/><path id="p54" d="M256.08,350.47l1.93,1.93-1.93,1.93h-12.9l-1.93-1.93,1.93-1.93h12.9Z" fill="white" fill-opacity="0.05"/><path id="p55" d="M238.67,354.98l1.93-1.93,1.93,1.93v12.9l-1.93,1.93-1.93-1.93v-12.9Z" fill="white" fill-opacity="0.05"/><path id="p56" d="M256.73,354.98l1.93-1.93,1.93,1.93v12.9l-1.93,1.93-1.93-1.93v-12.9Z" fill="white" fill-opacity="0.05"/><path id="p57" d="M256.08,368.52l1.93,1.93-1.93,1.93h-12.9l-1.93-1.93,1.93-1.93h12.9Z" fill="white" fill-opacity="0.05"/><path id="p61" d="M298.3,332.41l1.93,1.93-1.93,1.93h-12.9l-1.93-1.93,1.93-1.93h12.9Z" fill="white" fill-opacity="0.05"/><path id="p62" d="M280.89,336.93l1.93-1.93,1.93,1.93v12.9l-1.93,1.93-1.93-1.93v-12.9Z" fill="white" fill-opacity="0.05"/><path id="p63" d="M298.94,336.93l1.93-1.93,1.93,1.93v12.9l-1.93,1.93-1.93-1.93v-12.9Z" fill="white" fill-opacity="0.05"/><path id="p64" d="M298.3,350.47l1.93,1.93-1.93,1.93h-12.9l-1.93-1.93,1.93-1.93h12.9Z" fill="white" fill-opacity="0.05"/><path id="p65" d="M280.89,354.98l1.93-1.93,1.93,1.93v12.9l-1.93,1.93-1.93-1.93v-12.9Z" fill="white" fill-opacity="0.05"/><path id="p66" d="M298.94,354.98l1.93-1.93,1.93,1.93v12.9l-1.93,1.93-1.93-1.93v-12.9Z" fill="white" fill-opacity="0.05"/><path id="p67" d="M298.3,368.52l1.93,1.93-1.93,1.93h-12.9l-1.93-1.93,1.93-1.93h12.9Z" fill="white" fill-opacity="0.05"/><path id="p71" d="M340.49,332.41l1.93,1.93-1.93,1.93h-12.9l-1.93-1.93,1.93-1.93h12.9Z" fill="white" fill-opacity="0.05"/><path id="p72" d="M323.08,336.93l1.93-1.93,1.93,1.93v12.9l-1.93,1.93-1.93-1.93v-12.9Z" fill="white" fill-opacity="0.05"/><path id="p73" d="M341.13,336.93l1.93-1.93,1.93,1.93v12.9l-1.93,1.93-1.93-1.93v-12.9Z" fill="white" fill-opacity="0.05"/><path id="p74" d="M340.49,350.47l1.93,1.93-1.93,1.93h-12.9l-1.93-1.93,1.93-1.93h12.9Z" fill="white" fill-opacity="0.05"/><path id="p75" d="M323.08,354.98l1.93-1.93,1.93,1.93v12.9l-1.93,1.93-1.93-1.93v-12.9Z" fill="white" fill-opacity="0.05"/><path id="p76" d="M341.13,354.98l1.93-1.93,1.93,1.93v12.9l-1.93,1.93-1.93-1.93v-12.9Z" fill="white" fill-opacity="0.05"/><path id="p77" d="M340.49,368.52l1.93,1.93-1.93,1.93h-12.9l-1.93-1.93,1.93-1.93h12.9Z" fill="white" fill-opacity="0.05"/><path id="p81" d="M366.41,332.41l1.93,1.93-1.93,1.93h-12.9l-1.93-1.93,1.93-1.93h12.9Z" fill="white" fill-opacity="0.05"/><path id="p82" d="M349,336.93l1.93-1.93,1.93,1.93v12.9l-1.93,1.93-1.93-1.93v-12.9Z" fill="white" fill-opacity="0.05"/><path id="p83" d="M367.05,336.93l1.93-1.93,1.93,1.93v12.9l-1.93,1.93-1.93-1.93v-12.9Z" fill="white" fill-opacity="0.05"/><path id="p84" d="M366.41,350.47l1.93,1.93-1.93,1.93h-12.9l-1.93-1.93,1.93-1.93h12.9Z" fill="white" fill-opacity="0.05"/><path id="p85" d="M349,354.98l1.93-1.93,1.93,1.93v12.9l-1.93,1.93-1.93-1.93v-12.9Z" fill="white" fill-opacity="0.05"/><path id="p86" d="M367.05,354.98l1.93-1.93,1.93,1.93v12.9l-1.93,1.93-1.93-1.93v-12.9Z" fill="white" fill-opacity="0.05"/><path id="p87" d="M366.41,368.52l1.93,1.93-1.93,1.93h-12.9l-1.93-1.93,1.93-1.93h12.9Z" fill="white" fill-opacity="0.05"/><path id="p91" d="M408.62,332.41l1.93,1.93-1.93,1.93h-12.9l-1.93-1.93,1.93-1.93h12.9Z" fill="white" fill-opacity="0.05"/><path id="p92" d="M391.22,336.93l1.93-1.93,1.93,1.93v12.9l-1.93,1.93-1.93-1.93v-12.9Z" fill="white" fill-opacity="0.05"/><path id="p93" d="M409.27,336.93l1.93-1.93,1.93,1.93v12.9l-1.93,1.93-1.93-1.93v-12.9Z" fill="white" fill-opacity="0.05"/><path id="p94" d="M408.62,350.47l1.93,1.93-1.93,1.93h-12.9l-1.93-1.93,1.93-1.93h12.9Z" fill="white" fill-opacity="0.05"/><path id="p95" d="M391.22,354.98l1.93-1.93,1.93,1.93v12.9l-1.93,1.93-1.93-1.93v-12.9Z" fill="white" fill-opacity="0.05"/><path id="p96" d="M409.27,354.98l1.93-1.93,1.93,1.93v12.9l-1.93,1.93-1.93-1.93v-12.9Z" fill="white" fill-opacity="0.05"/><path id="p97" d="M408.62,368.52l1.93,1.93-1.93,1.93h-12.9l-1.93-1.93,1.93-1.93h12.9Z" fill="white" fill-opacity="0.05"/><path id="p101" d="M434.55,332.41l1.93,1.93-1.93,1.93h-12.9l-1.93-1.93,1.93-1.93h12.9Z" fill="white" fill-opacity="0.05"/><path id="p102" d="M417.14,336.93l1.93-1.93,1.93,1.93v12.9l-1.93,1.93-1.93-1.93v-12.9Z" fill="white" fill-opacity="0.05"/><path id="p103" d="M435.19,336.93l1.93-1.93,1.93,1.93v12.9l-1.93,1.93-1.93-1.93v-12.9Z" fill="white" fill-opacity="0.05"/><path id="p104" d="M434.55,350.47l1.93,1.93-1.93,1.93h-12.9l-1.93-1.93,1.93-1.93h12.9Z" fill="white" fill-opacity="0.05"/><path id="p105" d="M417.14,354.98l1.93-1.93,1.93,1.93v12.9l-1.93,1.93-1.93-1.93v-12.9Z" fill="white" fill-opacity="0.05"/><path id="p106" d="M435.19,354.98l1.93-1.93,1.93,1.93v12.9l-1.93,1.93-1.93-1.93v-12.9Z" fill="white" fill-opacity="0.05"/><path id="p107" d="M434.55,368.52l1.93,1.93-1.93,1.93h-12.9l-1.93-1.93,1.93-1.93h12.9Z" fill="white" fill-opacity="0.05"/><path id="p111" d="M476.76,332.41l1.93,1.93-1.93,1.93h-12.9l-1.93-1.93,1.93-1.93h12.9Z" fill="white" fill-opacity="0.05"/><path id="p112" d="M459.35,336.93l1.93-1.93,1.93,1.93v12.9l-1.93,1.93-1.93-1.93v-12.9Z" fill="white" fill-opacity="0.05"/><path id="p113" d="M477.41,336.93l1.93-1.93,1.93,1.93v12.9l-1.93,1.93-1.93-1.93v-12.9Z" fill="white" fill-opacity="0.05"/><path id="p114" d="M476.76,350.47l1.93,1.93-1.93,1.93h-12.9l-1.93-1.93,1.93-1.93h12.9Z" fill="white" fill-opacity="0.05"/><path id="p115" d="M459.35,354.98l1.93-1.93,1.93,1.93v12.9l-1.93,1.93-1.93-1.93v-12.9Z" fill="white" fill-opacity="0.05"/><path id="p116" d="M477.41,354.98l1.93-1.93,1.93,1.93v12.9l-1.93,1.93-1.93-1.93v-12.9Z" fill="white" fill-opacity="0.05"/><path id="p117" d="M476.76,368.52l1.93,1.93-1.93,1.93h-12.9l-1.93-1.93,1.93-1.93h12.9Z" fill="white" fill-opacity="0.05"/><path id="p121" d="M502.68,332.41l1.93,1.93-1.93,1.93h-12.9l-1.93-1.93,1.93-1.93h12.9Z" fill="white" fill-opacity="0.05"/><path id="p122" d="M485.27,336.93l1.93-1.93,1.93,1.93v12.9l-1.93,1.93-1.93-1.93v-12.9Z" fill="white" fill-opacity="0.05"/><path id="p123" d="M503.33,336.93l1.93-1.93,1.93,1.93v12.9l-1.93,1.93-1.93-1.93v-12.9Z" fill="white" fill-opacity="0.05"/><path id="p124" d="M502.68,350.47l1.93,1.93-1.93,1.93h-12.9l-1.93-1.93,1.93-1.93h12.9Z" fill="white" fill-opacity="0.05"/><path id="p125" d="M485.27,354.98l1.93-1.93,1.93,1.93v12.9l-1.93,1.93-1.93-1.93v-12.9Z" fill="white" fill-opacity="0.05"/><path id="p126" d="M503.33,354.98l1.93-1.93,1.93,1.93v12.9l-1.93,1.93-1.93-1.93v-12.9Z" fill="white" fill-opacity="0.05"/><path id="p127" d="M502.68,368.52l1.93,1.93-1.93,1.93h-12.9l-1.93-1.93,1.93-1.93h12.9Z" fill="white" fill-opacity="0.05"/><path id="pcolon1" d="M200.49,346.34v-4.35h4.29v4.35h-4.29Zm0,16.47v-4.35h4.29v4.35h-4.29Z" fill="white"/><path id="pcolon2" d="M268.6,346.34v-4.35h4.29v4.35h-4.29Zm0,16.47v-4.35h4.29v4.35h-4.29Z" fill="white"/><path id="pcolon3" d="M310.78,346.34v-4.35h4.29v4.35h-4.29Zm0,16.47v-4.35h4.29v4.35h-4.29Z" fill="white"/><path id="pcolon4" d="M378.92,346.34v-4.35h4.29v4.35h-4.29Zm0,16.47v-4.35h4.29v4.35h-4.29Z" fill="white"/><path id="pcolon5" d="M447.06,346.34v-4.35h4.29v4.35h-4.29Zm0,16.47v-4.35h4.29v4.35h-4.29Z" fill="white"/><style>';
    }

}