// SPDX-License-Identifier: None
// AudioGenesis Contracts v0.0.1t
// Creator: Chance Santana-Wees

pragma solidity ^0.8.11;

import './ERC721A.sol';
import "@openzeppelin/contracts/token/common/ERC2981.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";

interface IAudioGenesisRenderer {
    function constructTokenURI(
        string memory websocket,
        string memory jsonRPC,
        address[] memory customListeners,
        string memory customVisualizer,
        string memory customVisualizerName,
        uint256 tokenData
    ) external view returns (string memory);
}

interface IAudioGenesis {
    function totalSupply() external returns (uint256);
    function luftDropReserve() external returns (uint256);
    function merkleRoot() external returns (bytes32);
    function tokenIdToData(uint256 i) external returns (uint256);
    function ownerOf(uint256 i) external returns (address);
}

contract AudioGenesis is ERC2981, ERC721A, Ownable {
    event URI(string value, uint256 id);

    IAudioGenesis constant v1 = IAudioGenesis(0xE812FC216e7A86a5aC4e2517b86c46d8b9860A9E);
    IAudioGenesisRenderer constant renderer = IAudioGenesisRenderer(address(0x857aEc11dc3E31fB6e069b0559C11B4f94513Fa6));
    
    uint256 constant ALLOWLIST  = 1 << 8;
    uint256 constant PUBLIC     = 2 << 8;
    uint256 constant MINTED     = 3 << 8;

    uint256 public luftDropReserve = 55;
    uint256 public constant maxSupply = 555;
    uint256 public constant pricePerMint = 0.1 ether;

    uint256 public mintStart = 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF;
    bytes32 public merkleRoot = bytes32(uint(0xf06cba1cd6a5081e50548eaee72700c4f3d4ac4fd836a3004826e66c55bc4cd7));

    string public defaultWebsocketAPI = "wss://main-light.eth.linkpool.io/ws";
    string public defaultJSONAPI = "https://main-light.eth.linkpool.io/";

    mapping(address => uint256) private AllowedTokensMinted;

    mapping(uint256 => bool) private tokenOverridesEndpoints;
    mapping(uint256 => string) public tokenToWebsocketEndpoint;
    mapping(uint256 => string) public tokenToJSONEndpoint;
    mapping(uint256 => uint256) public tokenIdToData;
    mapping(uint256 => address[]) public tokenIdToCustomListeners;
    mapping(uint256 => string) public tokenIdToCustomVisualizer;
    mapping(uint256 => string) public tokenIdToCustomVisualizerName;

    string private _contractURI = "data:application/json;base64,ewogICJuYW1lIjogIkF1ZGlvR2VuZXNpcyIsCiAgImRlc2NyaXB0aW9uIjogIkFuIGV4cGVyaW1lbnRhbCAxMDAlIG9uLWNoYWluIG11bHRpbWVkaWEgTkZUIHRoYXQgYXVkaW8tdmlzdWFsaXplcyB0aGUgb24tY2hhaW4gZXZlbnRzIGVtaXR0ZWQgYnkgTkZUIHRyYW5zZmVycyBhbmQgc2FsZXMuIiwKICAiaW1hZ2UiOiAiZGF0YTppbWFnZS9zdmcreG1sO2Jhc2U2NCxQRDk0Yld3Z2RtVnljMmx2YmowaU1TNHdJaUJsYm1OdlpHbHVaejBpVlZSR0xUZ2lQejRLUEhOMlp5QnpkSGxzWlQwaVltRmphMmR5YjNWdVpDMWpiMnh2Y2pwaWJHRmpheUlnZG1sbGQwSnZlRDBpTUNBd0lERmxNeUF4WlRNaUlIaHRiRzV6UFNKb2RIUndPaTh2ZDNkM0xuY3pMbTl5Wnk4eU1EQXdMM04yWnlJK0NqeHpkSGxzWlQ1MFpYaDBJSHNLWm1sc2JEb2dkMmhwZEdVN0NuTjBjbTlyWlRvZ2QyaHBkR1U3Q25OMGNtOXJaUzEzYVdSMGFEb2dOSEI0T3dwbWIyNTBMWE5wZW1VNklEaGxiVHNLWm05dWRDMW1ZVzFwYkhrNklDZERiM1Z5YVdWeUlFNWxkeWNzSUcxdmJtOXpjR0ZqWlRzS2ZRcHlaV04wTG5KbFkzUWdld3AzYVdSMGFEb2dNVEF4Y0hnN0NtaGxhV2RvZERvZ01UQXdNSEI0T3dwOVBDOXpkSGxzWlQ0S1BISmxZM1FnWTJ4aGMzTTlJbkpsWTNRaUlHWnBiR3c5SWlNNFFqQXdNemdpUGdvOFlXNXBiV0YwWlNCaGRIUnlhV0oxZEdWT1lXMWxQU0o1SWlCallXeGpUVzlrWlQwaVpHbHpZM0psZEdVaUlHUjFjajBpTUM0MWN5SWdjbVZ3WldGMFEyOTFiblE5SW1sdVpHVm1hVzVwZEdVaUlIWmhiSFZsY3owaU5UQXdPelUxTURzMk1EQTdOalV3T3pZMU1EczJOVEE3TmpBd096WXdNRHMxTlRBN05UQXdPelV3TURzMU1EQWlMejRLUEM5eVpXTjBQZ284Y21WamRDQmpiR0Z6Y3owaWNtVmpkQ0lnZUQwaU1UQXdJaUJtYVd4c1BTSWpaakF3SWo0S1BHRnVhVzFoZEdVZ1lYUjBjbWxpZFhSbFRtRnRaVDBpZVNJZ1kyRnNZMDF2WkdVOUltUnBjMk55WlhSbElpQmtkWEk5SWpBdU5YTWlJSEpsY0dWaGRFTnZkVzUwUFNKcGJtUmxabWx1YVhSbElpQjJZV3gxWlhNOUlqUTFNRHMwTlRBN05UQXdPelV3TURzME5UQTdOREF3T3pRd01Ec3pOVEE3TXpVd096TTFNRHMwTURBN05EVXdJaTgrQ2p3dmNtVmpkRDRLUEhKbFkzUWdZMnhoYzNNOUluSmxZM1FpSUhnOUlqSXdNQ0lnWm1sc2JEMGlJMFpHT0VNd01DSStDanhoYm1sdFlYUmxJR0YwZEhKcFluVjBaVTVoYldVOUlua2lJR05oYkdOTmIyUmxQU0prYVhOamNtVjBaU0lnWkhWeVBTSXdMalZ6SWlCeVpYQmxZWFJEYjNWdWREMGlhVzVrWldacGJtbDBaU0lnZG1Gc2RXVnpQU0kwTURBN05EQXdPek0xTURzek1EQTdNalV3T3pJMU1Ec3lOVEE3TXpBd096TXdNRHN6TlRBN016VXdPelF3TUNJdlBnbzhMM0psWTNRK0NqeHlaV04wSUdOc1lYTnpQU0p5WldOMElpQjRQU0l6TURBaUlHWnBiR3c5SWlORVJFUTNNREFpUGdvOFlXNXBiV0YwWlNCaGRIUnlhV0oxZEdWT1lXMWxQU0o1SWlCallXeGpUVzlrWlQwaVpHbHpZM0psZEdVaUlHUjFjajBpTUM0MWN5SWdjbVZ3WldGMFEyOTFiblE5SW1sdVpHVm1hVzVwZEdVaUlIWmhiSFZsY3owaU5EQXdPelF3TURzek5UQTdNekF3T3pJeU1Ec3lNakE3TWpJd096TXdNRHN6TURBN016VXdPek0xTURzME1EQWlMejRLUEM5eVpXTjBQZ284Y21WamRDQmpiR0Z6Y3owaWNtVmpkQ0lnZUQwaU5EQXdJaUJtYVd4c1BTSWpNekJGUlRNd0lqNEtQR0Z1YVcxaGRHVWdZWFIwY21saWRYUmxUbUZ0WlQwaWVTSWdZMkZzWTAxdlpHVTlJbVJwYzJOeVpYUmxJaUJrZFhJOUlqQXVOWE1pSUhKbGNHVmhkRU52ZFc1MFBTSnBibVJsWm1sdWFYUmxJaUIyWVd4MVpYTTlJalExTURzME5UQTdOVEF3T3pVd01EczBOVEE3TkRBd096TTFNRHN6TlRBN016VXdPelF3TURzME1EQTdORFV3SWk4K0Nqd3ZjbVZqZEQ0S1BISmxZM1FnWTJ4aGMzTTlJbkpsWTNRaUlIZzlJalV3TUNJZ1ptbHNiRDBpSXpZMlppSStDanhoYm1sdFlYUmxJR0YwZEhKcFluVjBaVTVoYldVOUlua2lJR05oYkdOTmIyUmxQU0prYVhOamNtVjBaU0lnWkhWeVBTSXdMalZ6SWlCeVpYQmxZWFJEYjNWdWREMGlhVzVrWldacGJtbDBaU0lnZG1Gc2RXVnpQU0kyTURBN05qVXdPemN3TURzM05UQTdOelV3T3pjMU1EczNNREE3TmpBd096VTFNRHMxTlRBN05UVXdPell3TUNJdlBnbzhMM0psWTNRK0NqeHlaV04wSUdOc1lYTnpQU0p5WldOMElpQjRQU0kyTURBaUlHWnBiR3c5SWlNMFFqQXdPRElpUGdvOFlXNXBiV0YwWlNCaGRIUnlhV0oxZEdWT1lXMWxQU0o1SWlCallXeGpUVzlrWlQwaVpHbHpZM0psZEdVaUlHUjFjajBpTUM0MWN5SWdjbVZ3WldGMFEyOTFiblE5SW1sdVpHVm1hVzVwZEdVaUlIWmhiSFZsY3owaU9EQXdPemd3TURzNE1EQTdPRFV3T3pnMU1EczRNREE3T0RBd096YzFNRHMzTlRBN056VXdPemd3TURzNE1EQWlMejRLUEM5eVpXTjBQZ284Y21WamRDQmpiR0Z6Y3owaWNtVmpkQ0lnZUQwaU56QXdJaUJtYVd4c1BTSWpPRUl6TXpaQklqNEtQR0Z1YVcxaGRHVWdZWFIwY21saWRYUmxUbUZ0WlQwaWVTSWdZMkZzWTAxdlpHVTlJbVJwYzJOeVpYUmxJaUJrZFhJOUlqQXVOWE1pSUhKbGNHVmhkRU52ZFc1MFBTSnBibVJsWm1sdWFYUmxJaUIyWVd4MVpYTTlJamt5TlRzNU1qVTdPVEkxT3pnM05UczROelU3T0RVd096ZzFNRHM0TlRBN09ESTFPemd5TlRzNE56VTdPVEkxSWk4K0Nqd3ZjbVZqZEQ0S1BISmxZM1FnWTJ4aGMzTTlJbkpsWTNRaUlIZzlJamd3TUNJZ1ptbHNiRDBpSTJZek5pSStDanhoYm1sdFlYUmxJR0YwZEhKcFluVjBaVTVoYldVOUlua2lJR05oYkdOTmIyUmxQU0prYVhOamNtVjBaU0lnWkhWeVBTSXdMalZ6SWlCeVpYQmxZWFJEYjNWdWREMGlhVzVrWldacGJtbDBaU0lnZG1Gc2RXVnpQU0k1T0RVN09UZzFPems0TlRzNU56VTdPVGN3T3prMk5UczVOalU3T1RZMU96azNNRHM1TnpVN09UZ3dPems0TUNJdlBnbzhMM0psWTNRK0NqeHlaV04wSUdOc1lYTnpQU0p5WldOMElpQjRQU0k1TURBaUlHWnBiR3c5SWlObU1EQWlQZ284WVc1cGJXRjBaU0JoZEhSeWFXSjFkR1ZPWVcxbFBTSjVJaUJqWVd4alRXOWtaVDBpWkdselkzSmxkR1VpSUdSMWNqMGlNQzQxY3lJZ2NtVndaV0YwUTI5MWJuUTlJbWx1WkdWbWFXNXBkR1VpSUhaaGJIVmxjejBpT1RrMU96azVOVHM1T1RVN09UazFPems1TURzNU9UQTdPVGcxT3prNE5UczVPRFU3T1Rrd096azVNRHM1T1RVaUx6NEtQQzl5WldOMFBnbzhaeUIwY21GdWMyWnZjbTA5SW5SeVlXNXpiR0YwWlNneU5UQWdNVGMxS1NCelkyRnNaU2d4TGpJMUtTSStDanh3WVhSb0lHUTlJazAwTWpRdU5DQXlNVFF1TjB3M01pNDBJRFl1TmtNME15NDRMVEV3TGpNZ01DQTJMakVnTUNBME55NDVWalEyTkdNd0lETTNMalVnTkRBdU55QTJNQzR4SURjeUxqUWdOREV1TTJ3ek5USXRNakE0WXpNeExqUXRNVGd1TlNBek1TNDFMVFkwTGpFZ01DMDRNaTQyZWlJZ1ptbHNiRDBpSTBaR1JrWkdSa0pDSWk4K0Nqd3ZaejRLUEhSbGVIUWdlRDBpTlRBaUlIazlJakUxTUNJZ2RHVjRkRXhsYm1kMGFEMGlPVEFsSWo1QlZVUkpUend2ZEdWNGRENDhkR1Y0ZENCNFBTSTFNQ0lnZVQwaU9UVXdJaUIwWlhoMFRHVnVaM1JvUFNJNU1DVWlQa2RGVGtWVFNWTThMM1JsZUhRK1BDOXpkbWMrIiwKICAiZXh0ZXJuYWxfbGluayI6ICJodHRwczovL3R3aXR0ZXIuY29tL0ltcG9zc2libGVORlQiLAogICJzZWxsZXJfZmVlX2Jhc2lzX3BvaW50cyI6IDEwMDAsCiAgImZlZV9yZWNpcGllbnQiOiAiMHhjRDRhNzE1NzcwNjBjMzgwQzM3NTU1NGNBOTlCNDBENDQ4NEQyYTA1Igp9";

    constructor()
        ERC721A("AudioGenesis", "AG")
    {
        _setDefaultRoyalty(owner(), 750);
    }

    function init() external onlyOwner() {
        uint256 i = totalSupply()+1;
        uint256 m = v1.totalSupply()+1;
        if(m - i > 5) m = i+5;

        for(; i < m; i++) {
            _safeMint(v1.ownerOf(i), 1);
            tokenIdToData[i] = v1.tokenIdToData(i);
        }

        merkleRoot = v1.merkleRoot();
        luftDropReserve = v1.luftDropReserve();
    }

    function setMerkleRoot(uint256 _merkleRoot) external onlyOwner {
        merkleRoot = bytes32(_merkleRoot);
    }

    function pauseMint() external onlyOwner {
        mintStart = 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF;
    }

    function setAllowlistStart(uint256 timestamp) external onlyOwner {
        mintStart = timestamp;
    }

    function startPublicMint() external onlyOwner {
        mintStart = block.timestamp - 1 days;
    }

    function mintForCreator() external onlyOwner {
        //Mint for Creator
        require(_numberMinted(address(0x2DDB405238368695f34d30a80AB60c449aa5cE48)) == 0, "ALREADY_MINTED");
        _calcSeeds(5, address(0x2DDB405238368695f34d30a80AB60c449aa5cE48));
        _safeMint(address(0x2DDB405238368695f34d30a80AB60c449aa5cE48), 5);
    }

    function mintForLuftballons(uint256 quantity) external onlyOwner {
        if(luftDropReserve >= quantity) luftDropReserve -= quantity;
        else luftDropReserve = 0;
        require(totalSupply() + quantity - 1 < maxSupply, "MINTED_OUT");
        _calcSeeds(quantity, address(0x356E1363897033759181727e4BFf12396c51A7E0));
        _safeMint(address(0x356E1363897033759181727e4BFf12396c51A7E0), quantity);
    }

    function verifyMerkleProof(bytes32 leaf, bytes32[] memory merkleProof) public view returns (bool) {
        return MerkleProof.verify(merkleProof, merkleRoot, leaf);
    }

    function mint(uint256 quantity, uint256 maxAllowed, bytes32[] memory merkleProof) external payable {
        require(msg.sender == tx.origin, "NO_CONTRACT_MINTS");
        require(totalSupply() + quantity - 1 < maxSupply - luftDropReserve, "MINTED_OUT");
        require(msg.value == pricePerMint * quantity, "INCORRECT_PAYMENT");
        require(mintStart < block.timestamp, "NOT_MINTING");
        if(mintStart + 1 days < block.timestamp) {
            require(_numberMinted(_msgSenderERC721A()) == 0, "ALREADY_MINTED");
            require(quantity == 1, "EXCEEDS_ALLOWED");
        } else{
            require(maxAllowed >= quantity + _numberMinted(_msgSenderERC721A()), "EXCEEDS_ALLOWED");
            bytes32 leaf = keccak256(abi.encodePacked(maxAllowed,_msgSenderERC721A()));
            require(verifyMerkleProof(leaf, merkleProof), "BAD_PROOF");
        }

        _calcSeeds(quantity,_msgSenderERC721A());
        _safeMint(_msgSenderERC721A(),quantity);
        
        payable(owner()).transfer(msg.value);
    }
    
    uint256 private constant pulseModWeights = 0x0101054B64C864644B4B4B191919190A0A0A0A0A0A0505050503DB19;
    uint256 private constant pulseModOptions = 0x0305070B0A1113171D1F25292B2F353B3D4347494F53596165;
    uint256 private constant lowPulseWeights = 0x010103030201000B06;
    uint256 private constant lowPulseOptions = 0x01020406080C;
    uint256 private constant lfoModulWeights = 0x07060504030201001c07;
    uint256 private constant lfoModulOptions = 0x07060504030201;
    uint256 private constant timeModuWeights = 0x07060504030201001c07;
    uint256 private constant timeModuOptions = 0x07060504030201;
    uint256 private constant visualizWeights = 0x020202050a0a0505050a0a0a004c0c;
    uint256 private constant visualizOptions = 0x0b0a09080706050403020100;
    uint256 private constant filterTpWeights = 0x0505050a0a0a0a0a004108;
    uint256 private constant filterTpOptions = 0x0706050403020100;
    uint256 private constant filterFrWeights = 0x01020304030201001007;
    uint256 private constant filterFrOptions = 0x06050403020100;
    uint256 private constant filter_QWeights = 0x02051e1e1e140a007f07;
    uint256 private constant filter_QOptions = 0x643219140f0a05;
    uint256 private constant channel_Weights = 0x0102020105030a001807;
    uint256 private constant channel_Options = 0x06050403020100;

    function weightedRand(uint256 seed, uint256 weights, uint256 options) internal pure returns (uint256 choice) {
        uint256 length = weights & 0xFF;
        uint256 weightSum = (weights>>8) & 0xFFFF;
        uint256 r = seed%weightSum;
        uint256 sum=0;
        for (uint i = 0; i < length; i++) {
            sum += (weights >> (24+8*i)) & 0xFF;
            if (r <= sum){
                choice = (options>>(i*8)) & 0xFF;
                break;
            }
        }
    }

    function _calcSeeds(uint256 minted, address minter) private {
        uint256 token = _nextTokenId();
        uint256 seed = uint256(keccak256(abi.encodePacked(blockhash(block.number-1),minter, token)));
        while(token < _nextTokenId()+minted) {
            uint256 tokenData   = 0;
            tokenData |= weightedRand(seed, pulseModWeights, pulseModOptions);      seed = uint256(keccak256(abi.encodePacked(seed)));
            tokenData |= weightedRand(seed, lowPulseWeights, lowPulseOptions)<<8;   seed = uint256(keccak256(abi.encodePacked(seed)));
            tokenData |= (seed%6)<<16;                                              seed = uint256(keccak256(abi.encodePacked(seed)));
            tokenData |= weightedRand(seed, lfoModulWeights, lfoModulOptions)<<24;  seed = uint256(keccak256(abi.encodePacked(seed)));
            tokenData |= weightedRand(seed, timeModuWeights, timeModuOptions)<<32;  seed = uint256(keccak256(abi.encodePacked(seed)));
            tokenData |= weightedRand(seed, filterFrWeights, filterFrOptions)<<40;  seed = uint256(keccak256(abi.encodePacked(seed)));
            tokenData |= (seed%50)<<48;                                             seed = uint256(keccak256(abi.encodePacked(seed)));
            tokenData |= weightedRand(seed, filter_QWeights, filter_QOptions)<<56;  seed = uint256(keccak256(abi.encodePacked(seed)));
            tokenData |= (2*(((seed%1000)**2)/1000))<<64;                           seed = uint256(keccak256(abi.encodePacked(seed)));
            tokenData |= (500+10*(((seed%1000)**3)/1000000))<<80;                   seed = uint256(keccak256(abi.encodePacked(seed)));
            tokenData |= (seed%5)<<96;                                              seed = uint256(keccak256(abi.encodePacked(seed)));
            tokenData |= (seed%4)<<104;                                             seed = uint256(keccak256(abi.encodePacked(seed)));
            tokenData |= weightedRand(seed, visualizWeights, visualizOptions)<<112; seed = uint256(keccak256(abi.encodePacked(seed)));
            tokenData |= weightedRand(seed, filterTpWeights, filterTpOptions)<<120; seed = uint256(keccak256(abi.encodePacked(seed)));
            tokenData |= weightedRand(seed, channel_Weights, channel_Options)<<128; seed = uint256(keccak256(abi.encodePacked(seed)));
            tokenData |= token<<136;

            tokenIdToData[token] = tokenData;

            token++;
        }
    }

    function setDefaultRoyalty(uint96 basisPoints) external onlyOwner {
        _setDefaultRoyalty(owner(), basisPoints);
    }

    function contractURI() public view returns (string memory) {
        return _contractURI;
    }

    function setDefaultEndpoints(string memory websocketEndpoint, string memory jsonRPCEndpoint) external onlyOwner {
        defaultJSONAPI = jsonRPCEndpoint;
        defaultWebsocketAPI = websocketEndpoint;
    }

    function setCustomEndpoints(uint256 tokenID, string memory websocketEndpoint, string memory jsonRPCEndpoint) public {
        require(_msgSenderERC721A() == ownerOf(tokenID), "NOT_YOURS");
        tokenToWebsocketEndpoint[tokenID] = websocketEndpoint;
        tokenToJSONEndpoint[tokenID] = jsonRPCEndpoint;
        tokenOverridesEndpoints[tokenID] = true;
    }

    function clearCustomEndpoints(uint256 tokenID) public {
        require(_msgSenderERC721A() == ownerOf(tokenID), "NOT_YOURS");
        tokenOverridesEndpoints[tokenID] = false;
    }

    function setCustomVisualizer(uint256 tokenID, string memory fragmentShaderSrc, string memory visualizerName) public {
        require(_msgSenderERC721A() == ownerOf(tokenID), "NOT_YOURS");
        tokenIdToCustomVisualizer[tokenID] = fragmentShaderSrc;
        tokenIdToCustomVisualizerName[tokenID] = visualizerName;
    }

    function clearCustomVisualizer(uint256 tokenID) public {
        require(_msgSenderERC721A() == ownerOf(tokenID), "NOT_YOURS");
        tokenIdToCustomVisualizer[tokenID] = "";
        tokenIdToCustomVisualizerName[tokenID] = "";
    }

    function addCustomListener(uint256 tokenID, address listenerAddress) public {
        require(_msgSenderERC721A() == ownerOf(tokenID), "NOT_YOURS");
        tokenIdToCustomListeners[tokenID].push(listenerAddress);
    }

    function removeCustomListener(uint256 tokenID, uint256 listenerIndex) public {
        require(_msgSenderERC721A() == ownerOf(tokenID), "NOT_YOURS");
        uint256 length = tokenIdToCustomListeners[tokenID].length;
        require(listenerIndex < length);
        if(length > 1) tokenIdToCustomListeners[tokenID][listenerIndex] = tokenIdToCustomListeners[tokenID][length-1];
        tokenIdToCustomListeners[tokenID].pop();
    }

    function mintStatus() public view returns (uint256 status) {
        if(totalSupply() >= maxSupply - luftDropReserve) status += MINTED;
        else if(mintStart + 1 days < block.timestamp) status += PUBLIC;
        else if(mintStart < block.timestamp) status += ALLOWLIST; 
        return status + _numberMinted(_msgSenderERC721A());
    }

    function tokenURI(uint256 tokenID) public view override returns (string memory) {
        if(tokenOverridesEndpoints[tokenID]) {
            return renderer.constructTokenURI(
                tokenToWebsocketEndpoint[tokenID],
                tokenToJSONEndpoint[tokenID],
                tokenIdToCustomListeners[tokenID],
                tokenIdToCustomVisualizer[tokenID],
                tokenIdToCustomVisualizerName[tokenID],
                tokenIdToData[tokenID]);
        }

        return renderer.constructTokenURI(
                defaultWebsocketAPI,
                defaultJSONAPI,
                tokenIdToCustomListeners[tokenID],
                tokenIdToCustomVisualizer[tokenID],
                tokenIdToCustomVisualizerName[tokenID],
                tokenIdToData[tokenID]);
    }

    function _startTokenId() internal pure override returns (uint256) {
        return 1;
    }

    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC2981, ERC721A) returns (bool) {
        return ERC2981.supportsInterface(interfaceId) || ERC721A.supportsInterface(interfaceId); 
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/cryptography/MerkleProof.sol)

pragma solidity ^0.8.0;

/**
 * @dev These functions deal with verification of Merkle Tree proofs.
 *
 * The proofs can be generated using the JavaScript library
 * https://github.com/miguelmota/merkletreejs[merkletreejs].
 * Note: the hashing algorithm should be keccak256 and pair sorting should be enabled.
 *
 * See `test/utils/cryptography/MerkleProof.test.js` for some examples.
 *
 * WARNING: You should avoid using leaf values that are 64 bytes long prior to
 * hashing, or use a hash function other than keccak256 for hashing leaves.
 * This is because the concatenation of a sorted pair of internal nodes in
 * the merkle tree could be reinterpreted as a leaf value.
 */
library MerkleProof {
    /**
     * @dev Returns true if a `leaf` can be proved to be a part of a Merkle tree
     * defined by `root`. For this, a `proof` must be provided, containing
     * sibling hashes on the branch from the leaf to the root of the tree. Each
     * pair of leaves and each pair of pre-images are assumed to be sorted.
     */
    function verify(
        bytes32[] memory proof,
        bytes32 root,
        bytes32 leaf
    ) internal pure returns (bool) {
        return processProof(proof, leaf) == root;
    }

    /**
     * @dev Calldata version of {verify}
     *
     * _Available since v4.7._
     */
    function verifyCalldata(
        bytes32[] calldata proof,
        bytes32 root,
        bytes32 leaf
    ) internal pure returns (bool) {
        return processProofCalldata(proof, leaf) == root;
    }

    /**
     * @dev Returns the rebuilt hash obtained by traversing a Merkle tree up
     * from `leaf` using `proof`. A `proof` is valid if and only if the rebuilt
     * hash matches the root of the tree. When processing the proof, the pairs
     * of leafs & pre-images are assumed to be sorted.
     *
     * _Available since v4.4._
     */
    function processProof(bytes32[] memory proof, bytes32 leaf) internal pure returns (bytes32) {
        bytes32 computedHash = leaf;
        for (uint256 i = 0; i < proof.length; i++) {
            computedHash = _hashPair(computedHash, proof[i]);
        }
        return computedHash;
    }

    /**
     * @dev Calldata version of {processProof}
     *
     * _Available since v4.7._
     */
    function processProofCalldata(bytes32[] calldata proof, bytes32 leaf) internal pure returns (bytes32) {
        bytes32 computedHash = leaf;
        for (uint256 i = 0; i < proof.length; i++) {
            computedHash = _hashPair(computedHash, proof[i]);
        }
        return computedHash;
    }

    /**
     * @dev Returns true if the `leaves` can be proved to be a part of a Merkle tree defined by
     * `root`, according to `proof` and `proofFlags` as described in {processMultiProof}.
     *
     * _Available since v4.7._
     */
    function multiProofVerify(
        bytes32[] memory proof,
        bool[] memory proofFlags,
        bytes32 root,
        bytes32[] memory leaves
    ) internal pure returns (bool) {
        return processMultiProof(proof, proofFlags, leaves) == root;
    }

    /**
     * @dev Calldata version of {multiProofVerify}
     *
     * _Available since v4.7._
     */
    function multiProofVerifyCalldata(
        bytes32[] calldata proof,
        bool[] calldata proofFlags,
        bytes32 root,
        bytes32[] memory leaves
    ) internal pure returns (bool) {
        return processMultiProofCalldata(proof, proofFlags, leaves) == root;
    }

    /**
     * @dev Returns the root of a tree reconstructed from `leaves` and the sibling nodes in `proof`,
     * consuming from one or the other at each step according to the instructions given by
     * `proofFlags`.
     *
     * _Available since v4.7._
     */
    function processMultiProof(
        bytes32[] memory proof,
        bool[] memory proofFlags,
        bytes32[] memory leaves
    ) internal pure returns (bytes32 merkleRoot) {
        // This function rebuild the root hash by traversing the tree up from the leaves. The root is rebuilt by
        // consuming and producing values on a queue. The queue starts with the `leaves` array, then goes onto the
        // `hashes` array. At the end of the process, the last hash in the `hashes` array should contain the root of
        // the merkle tree.
        uint256 leavesLen = leaves.length;
        uint256 totalHashes = proofFlags.length;

        // Check proof validity.
        require(leavesLen + proof.length - 1 == totalHashes, "MerkleProof: invalid multiproof");

        // The xxxPos values are "pointers" to the next value to consume in each array. All accesses are done using
        // `xxx[xxxPos++]`, which return the current value and increment the pointer, thus mimicking a queue's "pop".
        bytes32[] memory hashes = new bytes32[](totalHashes);
        uint256 leafPos = 0;
        uint256 hashPos = 0;
        uint256 proofPos = 0;
        // At each step, we compute the next hash using two values:
        // - a value from the "main queue". If not all leaves have been consumed, we get the next leaf, otherwise we
        //   get the next hash.
        // - depending on the flag, either another value for the "main queue" (merging branches) or an element from the
        //   `proof` array.
        for (uint256 i = 0; i < totalHashes; i++) {
            bytes32 a = leafPos < leavesLen ? leaves[leafPos++] : hashes[hashPos++];
            bytes32 b = proofFlags[i] ? leafPos < leavesLen ? leaves[leafPos++] : hashes[hashPos++] : proof[proofPos++];
            hashes[i] = _hashPair(a, b);
        }

        if (totalHashes > 0) {
            return hashes[totalHashes - 1];
        } else if (leavesLen > 0) {
            return leaves[0];
        } else {
            return proof[0];
        }
    }

    /**
     * @dev Calldata version of {processMultiProof}
     *
     * _Available since v4.7._
     */
    function processMultiProofCalldata(
        bytes32[] calldata proof,
        bool[] calldata proofFlags,
        bytes32[] memory leaves
    ) internal pure returns (bytes32 merkleRoot) {
        // This function rebuild the root hash by traversing the tree up from the leaves. The root is rebuilt by
        // consuming and producing values on a queue. The queue starts with the `leaves` array, then goes onto the
        // `hashes` array. At the end of the process, the last hash in the `hashes` array should contain the root of
        // the merkle tree.
        uint256 leavesLen = leaves.length;
        uint256 totalHashes = proofFlags.length;

        // Check proof validity.
        require(leavesLen + proof.length - 1 == totalHashes, "MerkleProof: invalid multiproof");

        // The xxxPos values are "pointers" to the next value to consume in each array. All accesses are done using
        // `xxx[xxxPos++]`, which return the current value and increment the pointer, thus mimicking a queue's "pop".
        bytes32[] memory hashes = new bytes32[](totalHashes);
        uint256 leafPos = 0;
        uint256 hashPos = 0;
        uint256 proofPos = 0;
        // At each step, we compute the next hash using two values:
        // - a value from the "main queue". If not all leaves have been consumed, we get the next leaf, otherwise we
        //   get the next hash.
        // - depending on the flag, either another value for the "main queue" (merging branches) or an element from the
        //   `proof` array.
        for (uint256 i = 0; i < totalHashes; i++) {
            bytes32 a = leafPos < leavesLen ? leaves[leafPos++] : hashes[hashPos++];
            bytes32 b = proofFlags[i] ? leafPos < leavesLen ? leaves[leafPos++] : hashes[hashPos++] : proof[proofPos++];
            hashes[i] = _hashPair(a, b);
        }

        if (totalHashes > 0) {
            return hashes[totalHashes - 1];
        } else if (leavesLen > 0) {
            return leaves[0];
        } else {
            return proof[0];
        }
    }

    function _hashPair(bytes32 a, bytes32 b) private pure returns (bytes32) {
        return a < b ? _efficientHash(a, b) : _efficientHash(b, a);
    }

    function _efficientHash(bytes32 a, bytes32 b) private pure returns (bytes32 value) {
        /// @solidity memory-safe-assembly
        assembly {
            mstore(0x00, a)
            mstore(0x20, b)
            value := keccak256(0x00, 0x40)
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
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
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if the sender is not the owner.
     */
    function _checkOwner() internal view virtual {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (token/common/ERC2981.sol)

pragma solidity ^0.8.0;

import "../../interfaces/IERC2981.sol";
import "../../utils/introspection/ERC165.sol";

/**
 * @dev Implementation of the NFT Royalty Standard, a standardized way to retrieve royalty payment information.
 *
 * Royalty information can be specified globally for all token ids via {_setDefaultRoyalty}, and/or individually for
 * specific token ids via {_setTokenRoyalty}. The latter takes precedence over the first.
 *
 * Royalty is specified as a fraction of sale price. {_feeDenominator} is overridable but defaults to 10000, meaning the
 * fee is specified in basis points by default.
 *
 * IMPORTANT: ERC-2981 only specifies a way to signal royalty information and does not enforce its payment. See
 * https://eips.ethereum.org/EIPS/eip-2981#optional-royalty-payments[Rationale] in the EIP. Marketplaces are expected to
 * voluntarily pay royalties together with sales, but note that this standard is not yet widely supported.
 *
 * _Available since v4.5._
 */
abstract contract ERC2981 is IERC2981, ERC165 {
    struct RoyaltyInfo {
        address receiver;
        uint96 royaltyFraction;
    }

    RoyaltyInfo private _defaultRoyaltyInfo;
    mapping(uint256 => RoyaltyInfo) private _tokenRoyaltyInfo;

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(IERC165, ERC165) returns (bool) {
        return interfaceId == type(IERC2981).interfaceId || super.supportsInterface(interfaceId);
    }

    /**
     * @inheritdoc IERC2981
     */
    function royaltyInfo(uint256 _tokenId, uint256 _salePrice) public view virtual override returns (address, uint256) {
        RoyaltyInfo memory royalty = _tokenRoyaltyInfo[_tokenId];

        if (royalty.receiver == address(0)) {
            royalty = _defaultRoyaltyInfo;
        }

        uint256 royaltyAmount = (_salePrice * royalty.royaltyFraction) / _feeDenominator();

        return (royalty.receiver, royaltyAmount);
    }

    /**
     * @dev The denominator with which to interpret the fee set in {_setTokenRoyalty} and {_setDefaultRoyalty} as a
     * fraction of the sale price. Defaults to 10000 so fees are expressed in basis points, but may be customized by an
     * override.
     */
    function _feeDenominator() internal pure virtual returns (uint96) {
        return 10000;
    }

    /**
     * @dev Sets the royalty information that all ids in this contract will default to.
     *
     * Requirements:
     *
     * - `receiver` cannot be the zero address.
     * - `feeNumerator` cannot be greater than the fee denominator.
     */
    function _setDefaultRoyalty(address receiver, uint96 feeNumerator) internal virtual {
        require(feeNumerator <= _feeDenominator(), "ERC2981: royalty fee will exceed salePrice");
        require(receiver != address(0), "ERC2981: invalid receiver");

        _defaultRoyaltyInfo = RoyaltyInfo(receiver, feeNumerator);
    }

    /**
     * @dev Removes default royalty information.
     */
    function _deleteDefaultRoyalty() internal virtual {
        delete _defaultRoyaltyInfo;
    }

    /**
     * @dev Sets the royalty information for a specific token id, overriding the global default.
     *
     * Requirements:
     *
     * - `receiver` cannot be the zero address.
     * - `feeNumerator` cannot be greater than the fee denominator.
     */
    function _setTokenRoyalty(
        uint256 tokenId,
        address receiver,
        uint96 feeNumerator
    ) internal virtual {
        require(feeNumerator <= _feeDenominator(), "ERC2981: royalty fee will exceed salePrice");
        require(receiver != address(0), "ERC2981: Invalid parameters");

        _tokenRoyaltyInfo[tokenId] = RoyaltyInfo(receiver, feeNumerator);
    }

    /**
     * @dev Resets royalty information for the token id back to the global default.
     */
    function _resetTokenRoyalty(uint256 tokenId) internal virtual {
        delete _tokenRoyaltyInfo[tokenId];
    }
}

// SPDX-License-Identifier: MIT
// ERC721A Contracts v4.0.0
// Creator: Chiru Labs

pragma solidity ^0.8.4;

import './IERC721A.sol';

/**
 * @dev ERC721 token receiver interface.
 */
interface ERC721A__IERC721Receiver {
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
}

/**
 * @dev Implementation of https://eips.ethereum.org/EIPS/eip-721[ERC721] Non-Fungible Token Standard, including
 * the Metadata extension. Built to optimize for lower gas during batch mints.
 *
 * Assumes serials are sequentially minted starting at _startTokenId() (defaults to 0, e.g. 0, 1, 2, 3..).
 *
 * Assumes that an owner cannot have more than 2**64 - 1 (max value of uint64) of supply.
 *
 * Assumes that the maximum token id cannot exceed 2**256 - 1 (max value of uint256).
 */
contract ERC721A is IERC721A {
    event ConsecutiveTransfer(uint256 indexed fromTokenId, uint256 toTokenId, address indexed fromAddress, address indexed toAddress);

    // Mask of an entry in packed address data.
    uint256 private constant BITMASK_ADDRESS_DATA_ENTRY = (1 << 64) - 1;

    // The bit position of `numberMinted` in packed address data.
    uint256 private constant BITPOS_NUMBER_MINTED = 64;

    // The bit position of `numberBurned` in packed address data.
    uint256 private constant BITPOS_NUMBER_BURNED = 128;

    // The bit position of `aux` in packed address data.
    uint256 private constant BITPOS_AUX = 192;

    // Mask of all 256 bits in packed address data except the 64 bits for `aux`.
    uint256 private constant BITMASK_AUX_COMPLEMENT = (1 << 192) - 1;

    // The bit position of `startTimestamp` in packed ownership.
    uint256 private constant BITPOS_START_TIMESTAMP = 160;

    // The bit mask of the `burned` bit in packed ownership.
    uint256 private constant BITMASK_BURNED = 1 << 224;

    // The bit position of the `nextInitialized` bit in packed ownership.
    uint256 private constant BITPOS_NEXT_INITIALIZED = 225;

    // The bit mask of the `nextInitialized` bit in packed ownership.
    uint256 private constant BITMASK_NEXT_INITIALIZED = 1 << 225;

    // The tokenId of the next token to be minted.
    uint256 private _currentIndex;

    // The number of tokens burned.
    uint256 private _burnCounter;

    // Token name
    string private _name;

    // Token symbol
    string private _symbol;

    // Mapping from token ID to ownership details
    // An empty struct value does not necessarily mean the token is unowned.
    // See `_packedOwnershipOf` implementation for details.
    //
    // Bits Layout:
    // - [0..159]   `addr`
    // - [160..223] `startTimestamp`
    // - [224]      `burned`
    // - [225]      `nextInitialized`
    mapping(uint256 => uint256) private _packedOwnerships;

    // Mapping owner address to address data.
    //
    // Bits Layout:
    // - [0..63]    `balance`
    // - [64..127]  `numberMinted`
    // - [128..191] `numberBurned`
    // - [192..255] `aux`
    mapping(address => uint256) private _packedAddressData;

    // Mapping from token ID to approved address.
    mapping(uint256 => address) private _tokenApprovals;

    // Mapping from owner to operator approvals
    mapping(address => mapping(address => bool)) private _operatorApprovals;

    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
        _currentIndex = _startTokenId();
    }

    /**
     * @dev Returns the starting token ID.
     * To change the starting token ID, please override this function.
     */
    function _startTokenId() internal view virtual returns (uint256) {
        return 0;
    }

    /**
     * @dev Returns the next token ID to be minted.
     */
    function _nextTokenId() internal view returns (uint256) {
        return _currentIndex;
    }

    /**
     * @dev Returns the total number of tokens in existence.
     * Burned tokens will reduce the count.
     * To get the total number of tokens minted, please see `_totalMinted`.
     */
    function totalSupply() public view virtual returns (uint256) {
        // Counter underflow is impossible as _burnCounter cannot be incremented
        // more than `_currentIndex - _startTokenId()` times.
        unchecked {
            return _currentIndex - _burnCounter - _startTokenId();
        }
    }

    /**
     * @dev Returns the total amount of tokens minted in the contract.
     */
    function _totalMinted() internal view returns (uint256) {
        // Counter underflow is impossible as _currentIndex does not decrement,
        // and it is initialized to `_startTokenId()`
        unchecked {
            return _currentIndex - _startTokenId();
        }
    }

    /**
     * @dev Returns the total number of tokens burned.
     */
    function _totalBurned() internal view returns (uint256) {
        return _burnCounter;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        // The interface IDs are constants representing the first 4 bytes of the XOR of
        // all function selectors in the interface. See: https://eips.ethereum.org/EIPS/eip-165
        // e.g. `bytes4(i.functionA.selector ^ i.functionB.selector ^ ...)`
        return
            interfaceId == 0x01ffc9a7 || // ERC165 interface ID for ERC165.
            interfaceId == 0x80ac58cd || // ERC165 interface ID for ERC721.
            interfaceId == 0x5b5e139f; // ERC165 interface ID for ERC721Metadata.
    }

    /**
     * @dev See {IERC721-balanceOf}.
     */
    function balanceOf(address owner) public view override returns (uint256) {
        if (_addressToUint256(owner) == 0) revert BalanceQueryForZeroAddress();
        return _packedAddressData[owner] & BITMASK_ADDRESS_DATA_ENTRY;
    }

    /**
     * Returns the number of tokens minted by `owner`.
     */
    function _numberMinted(address owner) internal view returns (uint256) {
        return (_packedAddressData[owner] >> BITPOS_NUMBER_MINTED) & BITMASK_ADDRESS_DATA_ENTRY;
    }

    /**
     * Returns the number of tokens burned by or on behalf of `owner`.
     */
    function _numberBurned(address owner) internal view returns (uint256) {
        return (_packedAddressData[owner] >> BITPOS_NUMBER_BURNED) & BITMASK_ADDRESS_DATA_ENTRY;
    }

    /**
     * Returns the auxillary data for `owner`. (e.g. number of whitelist mint slots used).
     */
    function _getAux(address owner) internal view returns (uint64) {
        return uint64(_packedAddressData[owner] >> BITPOS_AUX);
    }

    /**
     * Sets the auxillary data for `owner`. (e.g. number of whitelist mint slots used).
     * If there are multiple variables, please pack them into a uint64.
     */
    function _setAux(address owner, uint64 aux) internal {
        uint256 packed = _packedAddressData[owner];
        uint256 auxCasted;
        assembly {
            // Cast aux without masking.
            auxCasted := aux
        }
        packed = (packed & BITMASK_AUX_COMPLEMENT) | (auxCasted << BITPOS_AUX);
        _packedAddressData[owner] = packed;
    }

    /**
     * Returns the packed ownership data of `tokenId`.
     */
    function _packedOwnershipOf(uint256 tokenId) private view returns (uint256) {
        uint256 curr = tokenId;

        unchecked {
            if (_startTokenId() <= curr)
                if (curr < _currentIndex) {
                    uint256 packed = _packedOwnerships[curr];
                    // If not burned.
                    if (packed & BITMASK_BURNED == 0) {
                        // Invariant:
                        // There will always be an ownership that has an address and is not burned
                        // before an ownership that does not have an address and is not burned.
                        // Hence, curr will not underflow.
                        //
                        // We can directly compare the packed value.
                        // If the address is zero, packed is zero.
                        while (packed == 0) {
                            packed = _packedOwnerships[--curr];
                        }
                        return packed;
                    }
                }
        }
        revert OwnerQueryForNonexistentToken();
    }

    /**
     * Returns the unpacked `TokenOwnership` struct from `packed`.
     */
    function _unpackedOwnership(uint256 packed) private pure returns (TokenOwnership memory ownership) {
        ownership.addr = address(uint160(packed));
        ownership.startTimestamp = uint64(packed >> BITPOS_START_TIMESTAMP);
        ownership.burned = packed & BITMASK_BURNED != 0;
    }

    /**
     * Returns the unpacked `TokenOwnership` struct at `index`.
     */
    function _ownershipAt(uint256 index) internal view returns (TokenOwnership memory) {
        return _unpackedOwnership(_packedOwnerships[index]);
    }

    /**
     * @dev Initializes the ownership slot minted at `index` for efficiency purposes.
     */
    function _initializeOwnershipAt(uint256 index) internal {
        if (_packedOwnerships[index] == 0) {
            _packedOwnerships[index] = _packedOwnershipOf(index);
        }
    }

    /**
     * Gas spent here starts off proportional to the maximum mint batch size.
     * It gradually moves to O(1) as tokens get transferred around in the collection over time.
     */
    function _ownershipOf(uint256 tokenId) internal view returns (TokenOwnership memory) {
        return _unpackedOwnership(_packedOwnershipOf(tokenId));
    }

    /**
     * @dev See {IERC721-ownerOf}.
     */
    function ownerOf(uint256 tokenId) public view virtual returns (address) {
        return address(uint160(_packedOwnershipOf(tokenId)));
    }

    /**
     * @dev See {IERC721Metadata-name}.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev See {IERC721Metadata-symbol}.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev See {IERC721Metadata-tokenURI}.
     */
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        if (!_exists(tokenId)) revert URIQueryForNonexistentToken();

        string memory baseURI = _baseURI();
        return bytes(baseURI).length != 0 ? string(abi.encodePacked(baseURI, _toString(tokenId))) : '';
    }

    /**
     * @dev Base URI for computing {tokenURI}. If set, the resulting URI for each
     * token will be the concatenation of the `baseURI` and the `tokenId`. Empty
     * by default, can be overriden in child contracts.
     */
    function _baseURI() internal view virtual returns (string memory) {
        return '';
    }

    /**
     * @dev Casts the address to uint256 without masking.
     */
    function _addressToUint256(address value) private pure returns (uint256 result) {
        assembly {
            result := value
        }
    }

    /**
     * @dev Casts the boolean to uint256 without branching.
     */
    function _boolToUint256(bool value) private pure returns (uint256 result) {
        assembly {
            result := value
        }
    }

    /**
     * @dev See {IERC721-approve}.
     */
    function approve(address to, uint256 tokenId) public override {
        address owner = address(uint160(_packedOwnershipOf(tokenId)));

        if (_msgSenderERC721A() != owner)
            if (!isApprovedForAll(owner, _msgSenderERC721A())) {
                revert ApprovalCallerNotOwnerNorApproved();
            }

        _tokenApprovals[tokenId] = to;
        emit Approval(owner, to, tokenId);
    }

    /**
     * @dev See {IERC721-getApproved}.
     */
    function getApproved(uint256 tokenId) public view override returns (address) {
        if (!_exists(tokenId)) revert ApprovalQueryForNonexistentToken();

        return _tokenApprovals[tokenId];
    }

    /**
     * @dev See {IERC721-setApprovalForAll}.
     */
    function setApprovalForAll(address operator, bool approved) public virtual override {
        if (operator == _msgSenderERC721A()) revert ApproveToCaller();

        _operatorApprovals[_msgSenderERC721A()][operator] = approved;
        emit ApprovalForAll(_msgSenderERC721A(), operator, approved);
    }

    /**
     * @dev See {IERC721-isApprovedForAll}.
     */
    function isApprovedForAll(address owner, address operator) public view virtual override returns (bool) {
        return _operatorApprovals[owner][operator];
    }

    /**
     * @dev See {IERC721-transferFrom}.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        _transfer(from, to, tokenId);
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        safeTransferFrom(from, to, tokenId, '');
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) public virtual override {
        _transfer(from, to, tokenId);
        if (to.code.length != 0)
            if (!_checkContractOnERC721Received(from, to, tokenId, _data)) {
                revert TransferToNonERC721ReceiverImplementer();
            }
    }

    /**
     * @dev Returns whether `tokenId` exists.
     *
     * Tokens can be managed by their owner or approved accounts via {approve} or {setApprovalForAll}.
     *
     * Tokens start existing when they are minted (`_mint`),
     */
    function _exists(uint256 tokenId) internal view returns (bool) {
        return
            _startTokenId() <= tokenId &&
            tokenId < _currentIndex && // If within bounds,
            _packedOwnerships[tokenId] & BITMASK_BURNED == 0; // and not burned.
    }

    /**
     * @dev Equivalent to `_safeMint(to, quantity, '')`.
     */
    function _safeMint(address to, uint256 quantity) internal {
        _safeMint(to, quantity, '');
    }

    /**
     * @dev Safely mints `quantity` tokens and transfers them to `to`.
     *
     * Requirements:
     *
     * - If `to` refers to a smart contract, it must implement
     *   {IERC721Receiver-onERC721Received}, which is called for each safe transfer.
     * - `quantity` must be greater than 0.
     *
     * Emits a {Transfer} event for each mint.
     */
    function _safeMint(
        address to,
        uint256 quantity,
        bytes memory _data
    ) internal {
        _mint(to, quantity);

        unchecked {
            if (to.code.length != 0) {
                uint256 end = _currentIndex;
                uint256 index = end - quantity;
                do {
                    if (!_checkContractOnERC721Received(address(0), to, index++, _data)) {
                        revert TransferToNonERC721ReceiverImplementer();
                    }
                } while (index < end);
                // Reentrancy protection.
                if (_currentIndex != end) revert();
            }
        }
    }

    /**
     * @dev Mints `quantity` tokens and transfers them to `to`.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - `quantity` must be greater than 0.
     *
     * Emits a {Transfer} event for each mint.
     */
    function _mint(address to, uint256 quantity) internal {
        uint256 startTokenId = _currentIndex;
        if (_addressToUint256(to) == 0) revert MintToZeroAddress();
        if (quantity == 0) revert MintZeroQuantity();

        _beforeTokenTransfers(address(0), to, startTokenId, quantity);

        // Overflows are incredibly unrealistic.
        // balance or numberMinted overflow if current value of either + quantity > 1.8e19 (2**64) - 1
        // updatedIndex overflows if _currentIndex + quantity > 1.2e77 (2**256) - 1
        unchecked {
            // Updates:
            // - `balance += quantity`.
            // - `numberMinted += quantity`.
            //
            // We can directly add to the balance and number minted.
            _packedAddressData[to] += quantity * ((1 << BITPOS_NUMBER_MINTED) | 1);

            // Updates:
            // - `address` to the owner.
            // - `startTimestamp` to the timestamp of minting.
            // - `burned` to `false`.
            // - `nextInitialized` to `quantity == 1`.
            _packedOwnerships[startTokenId] =
                _addressToUint256(to) |
                (block.timestamp << BITPOS_START_TIMESTAMP) |
                (_boolToUint256(quantity == 1) << BITPOS_NEXT_INITIALIZED);
            
            uint256 offset;
            do {
                emit Transfer(address(0), to, startTokenId + offset++);
            } while (offset < quantity);

            _currentIndex = startTokenId + quantity;
        }
        _afterTokenTransfers(address(0), to, startTokenId, quantity);
    }

    /**
     * @dev Transfers `tokenId` from `from` to `to`.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     *
     * Emits a {Transfer} event.
     */
    function _transfer(
        address from,
        address to,
        uint256 tokenId
    ) private {
        uint256 prevOwnershipPacked = _packedOwnershipOf(tokenId);

        if (address(uint160(prevOwnershipPacked)) != from) revert TransferFromIncorrectOwner();

        address approvedAddress = _tokenApprovals[tokenId];

        bool isApprovedOrOwner = (_msgSenderERC721A() == from ||
            isApprovedForAll(from, _msgSenderERC721A()) ||
            approvedAddress == _msgSenderERC721A());

        if (!isApprovedOrOwner) revert TransferCallerNotOwnerNorApproved();
        if (_addressToUint256(to) == 0) revert TransferToZeroAddress();

        _beforeTokenTransfers(from, to, tokenId, 1);

        // Clear approvals from the previous owner.
        if (_addressToUint256(approvedAddress) != 0) {
            delete _tokenApprovals[tokenId];
        }

        // Underflow of the sender's balance is impossible because we check for
        // ownership above and the recipient's balance can't realistically overflow.
        // Counter overflow is incredibly unrealistic as tokenId would have to be 2**256.
        unchecked {
            // We can directly increment and decrement the balances.
            --_packedAddressData[from]; // Updates: `balance -= 1`.
            ++_packedAddressData[to]; // Updates: `balance += 1`.

            // Updates:
            // - `address` to the next owner.
            // - `startTimestamp` to the timestamp of transfering.
            // - `burned` to `false`.
            // - `nextInitialized` to `true`.
            _packedOwnerships[tokenId] =
                _addressToUint256(to) |
                (block.timestamp << BITPOS_START_TIMESTAMP) |
                BITMASK_NEXT_INITIALIZED;

            // If the next slot may not have been initialized (i.e. `nextInitialized == false`) .
            if (prevOwnershipPacked & BITMASK_NEXT_INITIALIZED == 0) {
                uint256 nextTokenId = tokenId + 1;
                // If the next slot's address is zero and not burned (i.e. packed value is zero).
                if (_packedOwnerships[nextTokenId] == 0) {
                    // If the next slot is within bounds.
                    if (nextTokenId != _currentIndex) {
                        // Initialize the next slot to maintain correctness for `ownerOf(tokenId + 1)`.
                        _packedOwnerships[nextTokenId] = prevOwnershipPacked;
                    }
                }
            }
        }

        emit Transfer(from, to, tokenId);
        _afterTokenTransfers(from, to, tokenId, 1);
    }

    /**
     * @dev Equivalent to `_burn(tokenId, false)`.
     */
    function _burn(uint256 tokenId) internal virtual {
        _burn(tokenId, false);
    }

    /**
     * @dev Destroys `tokenId`.
     * The approval is cleared when the token is burned.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     *
     * Emits a {Transfer} event.
     */
    function _burn(uint256 tokenId, bool approvalCheck) internal virtual {
        uint256 prevOwnershipPacked = _packedOwnershipOf(tokenId);

        address from = address(uint160(prevOwnershipPacked));
        address approvedAddress = _tokenApprovals[tokenId];

        if (approvalCheck) {
            bool isApprovedOrOwner = (_msgSenderERC721A() == from ||
                isApprovedForAll(from, _msgSenderERC721A()) ||
                approvedAddress == _msgSenderERC721A());

            if (!isApprovedOrOwner) revert TransferCallerNotOwnerNorApproved();
        }

        _beforeTokenTransfers(from, address(0), tokenId, 1);

        // Clear approvals from the previous owner.
        if (_addressToUint256(approvedAddress) != 0) {
            delete _tokenApprovals[tokenId];
        }

        // Underflow of the sender's balance is impossible because we check for
        // ownership above and the recipient's balance can't realistically overflow.
        // Counter overflow is incredibly unrealistic as tokenId would have to be 2**256.
        unchecked {
            // Updates:
            // - `balance -= 1`.
            // - `numberBurned += 1`.
            //
            // We can directly decrement the balance, and increment the number burned.
            // This is equivalent to `packed -= 1; packed += 1 << BITPOS_NUMBER_BURNED;`.
            _packedAddressData[from] += (1 << BITPOS_NUMBER_BURNED) - 1;

            // Updates:
            // - `address` to the last owner.
            // - `startTimestamp` to the timestamp of burning.
            // - `burned` to `true`.
            // - `nextInitialized` to `true`.
            _packedOwnerships[tokenId] =
                _addressToUint256(from) |
                (block.timestamp << BITPOS_START_TIMESTAMP) |
                BITMASK_BURNED |
                BITMASK_NEXT_INITIALIZED;

            // If the next slot may not have been initialized (i.e. `nextInitialized == false`) .
            if (prevOwnershipPacked & BITMASK_NEXT_INITIALIZED == 0) {
                uint256 nextTokenId = tokenId + 1;
                // If the next slot's address is zero and not burned (i.e. packed value is zero).
                if (_packedOwnerships[nextTokenId] == 0) {
                    // If the next slot is within bounds.
                    if (nextTokenId != _currentIndex) {
                        // Initialize the next slot to maintain correctness for `ownerOf(tokenId + 1)`.
                        _packedOwnerships[nextTokenId] = prevOwnershipPacked;
                    }
                }
            }
        }

        emit Transfer(from, address(0), tokenId);
        _afterTokenTransfers(from, address(0), tokenId, 1);

        // Overflow not possible, as _burnCounter cannot be exceed _currentIndex times.
        unchecked {
            _burnCounter++;
        }
    }

    /**
     * @dev Internal function to invoke {IERC721Receiver-onERC721Received} on a target contract.
     *
     * @param from address representing the previous owner of the given token ID
     * @param to target address that will receive the tokens
     * @param tokenId uint256 ID of the token to be transferred
     * @param _data bytes optional data to send along with the call
     * @return bool whether the call correctly returned the expected magic value
     */
    function _checkContractOnERC721Received(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) private returns (bool) {
        try ERC721A__IERC721Receiver(to).onERC721Received(_msgSenderERC721A(), from, tokenId, _data) returns (
            bytes4 retval
        ) {
            return retval == ERC721A__IERC721Receiver(to).onERC721Received.selector;
        } catch (bytes memory reason) {
            if (reason.length == 0) {
                revert TransferToNonERC721ReceiverImplementer();
            } else {
                assembly {
                    revert(add(32, reason), mload(reason))
                }
            }
        }
    }

    /**
     * @dev Hook that is called before a set of serially-ordered token ids are about to be transferred. This includes minting.
     * And also called before burning one token.
     *
     * startTokenId - the first token id to be transferred
     * quantity - the amount to be transferred
     *
     * Calling conditions:
     *
     * - When `from` and `to` are both non-zero, `from`'s `tokenId` will be
     * transferred to `to`.
     * - When `from` is zero, `tokenId` will be minted for `to`.
     * - When `to` is zero, `tokenId` will be burned by `from`.
     * - `from` and `to` are never both zero.
     */
    function _beforeTokenTransfers(
        address from,
        address to,
        uint256 startTokenId,
        uint256 quantity
    ) internal virtual {}

    /**
     * @dev Hook that is called after a set of serially-ordered token ids have been transferred. This includes
     * minting.
     * And also called after one token has been burned.
     *
     * startTokenId - the first token id to be transferred
     * quantity - the amount to be transferred
     *
     * Calling conditions:
     *
     * - When `from` and `to` are both non-zero, `from`'s `tokenId` has been
     * transferred to `to`.
     * - When `from` is zero, `tokenId` has been minted for `to`.
     * - When `to` is zero, `tokenId` has been burned by `from`.
     * - `from` and `to` are never both zero.
     */
    function _afterTokenTransfers(
        address from,
        address to,
        uint256 startTokenId,
        uint256 quantity
    ) internal virtual {}

    /**
     * @dev Returns the message sender (defaults to `msg.sender`).
     *
     * If you are writing GSN compatible contracts, you need to override this function.
     */
    function _msgSenderERC721A() internal view virtual returns (address) {
        return msg.sender;
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function _toString(uint256 value) internal pure returns (string memory ptr) {
        assembly {
            // The maximum value of a uint256 contains 78 digits (1 byte per digit),
            // but we allocate 128 bytes to keep the free memory pointer 32-byte word aliged.
            // We will need 1 32-byte word to store the length,
            // and 3 32-byte words to store a maximum of 78 digits. Total: 32 + 3 * 32 = 128.
            ptr := add(mload(0x40), 128)
            // Update the free memory pointer to allocate.
            mstore(0x40, ptr)

            // Cache the end of the memory to calculate the length later.
            let end := ptr

            // We write the string from the rightmost digit to the leftmost digit.
            // The following is essentially a do-while loop that also handles the zero case.
            // Costs a bit more than early returning for the zero case,
            // but cheaper in terms of deployment and overall runtime costs.
            for {
                // Initialize and perform the first pass without check.
                let temp := value
                // Move the pointer 1 byte leftwards to point to an empty character slot.
                ptr := sub(ptr, 1)
                // Write the character to the pointer. 48 is the ASCII index of '0'.
                mstore8(ptr, add(48, mod(temp, 10)))
                temp := div(temp, 10)
            } temp {
                // Keep dividing `temp` until zero.
                temp := div(temp, 10)
            } {
                // Body of the for loop.
                ptr := sub(ptr, 1)
                mstore8(ptr, add(48, mod(temp, 10)))
            }

            let length := sub(end, ptr)
            // Move the pointer 32 bytes leftwards to make room for the length.
            ptr := sub(ptr, 32)
            // Store the length.
            mstore(ptr, length)
        }
    }
}

// SPDX-License-Identifier: MIT
// ERC721A Contracts v4.0.0
// Creator: Chiru Labs

pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

/**
 * @dev Interface of an ERC721A compliant contract.
 */
interface IERC721A is IERC721 {
    /**
     * The caller must own the token or be an approved operator.
     */
    error ApprovalCallerNotOwnerNorApproved();

    /**
     * The token does not exist.
     */
    error ApprovalQueryForNonexistentToken();

    /**
     * The caller cannot approve to their own address.
     */
    error ApproveToCaller();

    /**
     * Cannot query the balance for the zero address.
     */
    error BalanceQueryForZeroAddress();

    /**
     * Cannot mint to the zero address.
     */
    error MintToZeroAddress();

    /**
     * The quantity of tokens minted must be more than zero.
     */
    error MintZeroQuantity();

    /**
     * The token does not exist.
     */
    error OwnerQueryForNonexistentToken();

    /**
     * The caller must own the token or be an approved operator.
     */
    error TransferCallerNotOwnerNorApproved();

    /**
     * The token must be owned by `from`.
     */
    error TransferFromIncorrectOwner();

    /**
     * Cannot safely transfer to a contract that does not implement the ERC721Receiver interface.
     */
    error TransferToNonERC721ReceiverImplementer();

    /**
     * Cannot transfer to the zero address.
     */
    error TransferToZeroAddress();

    /**
     * The token does not exist.
     */
    error URIQueryForNonexistentToken();

    struct TokenOwnership {
        // The address of the owner.
        address addr;
        // Keeps track of the start time of ownership with minimal overhead for tokenomics.
        uint64 startTimestamp;
        // Whether the token has been burned.
        bool burned;
    }

    /**
     * @dev Returns the total amount of tokens stored by the contract.
     *
     * Burned tokens are calculated here, use `_totalMinted()` if you want to count just minted tokens.
     */
    function totalSupply() external view returns (uint256);

    // ==============================
    //            IERC165
    // ==============================

    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[EIP section]
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);

    // ==============================
    //            IERC721
    // ==============================

    /**
     * @dev Returns the number of tokens in ``owner``'s account.
     */
    function balanceOf(address owner) external view returns (uint256 balance);

    /**
     * @dev Returns the owner of the `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function ownerOf(uint256 tokenId) external view returns (address owner);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external;

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be have been allowed to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Transfers `tokenId` token from `from` to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {safeTransferFrom} whenever possible.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Gives permission to `to` to transfer `tokenId` token to another account.
     * The approval is cleared when the token is transferred.
     *
     * Only a single account can be approved at a time, so approving the zero address clears previous approvals.
     *
     * Requirements:
     *
     * - The caller must own the token or be an approved operator.
     * - `tokenId` must exist.
     *
     * Emits an {Approval} event.
     */
    function approve(address to, uint256 tokenId) external;

    /**
     * @dev Approve or remove `operator` as an operator for the caller.
     * Operators can call {transferFrom} or {safeTransferFrom} for any token owned by the caller.
     *
     * Requirements:
     *
     * - The `operator` cannot be the caller.
     *
     * Emits an {ApprovalForAll} event.
     */
    function setApprovalForAll(address operator, bool _approved) external;

    /**
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);

    // ==============================
    //        IERC721Metadata
    // ==============================

    /**
     * @dev Returns the token collection name.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the token collection symbol.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the Uniform Resource Identifier (URI) for `tokenId` token.
     */
    function tokenURI(uint256 tokenId) external view returns (string memory);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/ERC165.sol)

pragma solidity ^0.8.0;

import "./IERC165.sol";

/**
 * @dev Implementation of the {IERC165} interface.
 *
 * Contracts that want to implement ERC165 should inherit from this contract and override {supportsInterface} to check
 * for the additional interface id that will be supported. For example:
 *
 * ```solidity
 * function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
 *     return interfaceId == type(MyInterface).interfaceId || super.supportsInterface(interfaceId);
 * }
 * ```
 *
 * Alternatively, {ERC165Storage} provides an easier to use but more expensive implementation.
 */
abstract contract ERC165 is IERC165 {
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165).interfaceId;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (interfaces/IERC2981.sol)

pragma solidity ^0.8.0;

import "../utils/introspection/IERC165.sol";

/**
 * @dev Interface for the NFT Royalty Standard.
 *
 * A standardized way to retrieve royalty payment information for non-fungible tokens (NFTs) to enable universal
 * support for royalty payments across all NFT marketplaces and ecosystem participants.
 *
 * _Available since v4.5._
 */
interface IERC2981 is IERC165 {
    /**
     * @dev Returns how much royalty is owed and to whom, based on a sale price that may be denominated in any unit of
     * exchange. The royalty amount is denominated and should be paid in that same unit of exchange.
     */
    function royaltyInfo(uint256 tokenId, uint256 salePrice)
        external
        view
        returns (address receiver, uint256 royaltyAmount);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC721/IERC721.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721 is IERC165 {
    /**
     * @dev Emitted when `tokenId` token is transferred from `from` to `to`.
     */
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables `approved` to manage the `tokenId` token.
     */
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables or disables (`approved`) `operator` to manage all of its assets.
     */
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    /**
     * @dev Returns the number of tokens in ``owner``'s account.
     */
    function balanceOf(address owner) external view returns (uint256 balance);

    /**
     * @dev Returns the owner of the `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function ownerOf(uint256 tokenId) external view returns (address owner);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external;

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must have been allowed to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Transfers `tokenId` token from `from` to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {safeTransferFrom} whenever possible.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Gives permission to `to` to transfer `tokenId` token to another account.
     * The approval is cleared when the token is transferred.
     *
     * Only a single account can be approved at a time, so approving the zero address clears previous approvals.
     *
     * Requirements:
     *
     * - The caller must own the token or be an approved operator.
     * - `tokenId` must exist.
     *
     * Emits an {Approval} event.
     */
    function approve(address to, uint256 tokenId) external;

    /**
     * @dev Approve or remove `operator` as an operator for the caller.
     * Operators can call {transferFrom} or {safeTransferFrom} for any token owned by the caller.
     *
     * Requirements:
     *
     * - The `operator` cannot be the caller.
     *
     * Emits an {ApprovalForAll} event.
     */
    function setApprovalForAll(address operator, bool _approved) external;

    /**
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/IERC165.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC165 standard, as defined in the
 * https://eips.ethereum.org/EIPS/eip-165[EIP].
 *
 * Implementers can declare support of contract interfaces, which can then be
 * queried by others ({ERC165Checker}).
 *
 * For an implementation, see {ERC165}.
 */
interface IERC165 {
    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[EIP section]
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}