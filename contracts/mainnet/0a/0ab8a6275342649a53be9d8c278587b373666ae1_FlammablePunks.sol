pragma solidity 0.6.6;

import "ERC721.sol";
import "Ownable.sol";

contract FlammablePunks is ERC721, Ownable {
    uint256 private tokenCounter;
    uint256 private minURI;
    uint256 private maxURI;

    constructor() public ERC721("Flammable Punks", "FLAMS") {
        tokenCounter = 0;
        minURI = 0;
        maxURI = 9999;
        freeMint(0x3d67b76CF3dcc881255eb2262E788BE03b2f5B9F, 10);
        freeMint(0x0baeF0414391b623343b397466Cf9921fbd391EF, 10);
        freeMint(0x5f71Eb6a920Ed107bdFE75DD4fAa62401d7f3758, 10);
    }

    function rescuePunks(uint256 _quantity) public payable returns (bytes32) {
        require(tokenCounter < 10000, "All punks have been rescued!");
        require(
            tokenCounter + _quantity <= 10000,
            "There aren't that many punks left to be saved."
        );
        require(
            _quantity > 0 && _quantity <= 10,
            "Slow down hero! You can only rescue 10 punks at a time."
        );
        require(
            msg.value >= (0.02 * 10**18) * _quantity,
            "Not enough ETH, it costs 0.02 ETH to rescue each punk."
        );
        address rescuer = msg.sender;
        freeMint(rescuer, _quantity);
    }

    function uint2str(uint256 _i) internal pure returns (string memory str) {
        if (_i == 0) {
            return "0";
        }
        uint256 j = _i;
        uint256 length;
        while (j != 0) {
            length++;
            j /= 10;
        }
        bytes memory bstr = new bytes(length);
        uint256 k = length;
        j = _i;
        while (j != 0) {
            bstr[--k] = bytes1(uint8(48 + (j % 10)));
            j /= 10;
        }
        str = string(bstr);
    }

    function freeMint(address _rescuer, uint256 _quantity)
        private
        returns (bytes32)
    {
        uint256 randomNumber = uint256(
            keccak256(
                abi.encodePacked(
                    tokenCounter,
                    minURI,
                    maxURI,
                    _rescuer,
                    block.difficulty,
                    block.timestamp
                )
            )
        );

        uint256 vitalsProb = randomNumber % 10000;
        uint256 tokenURIBinary = randomNumber % 2;
        uint256 tokenURIIndex;
        if (tokenURIBinary == 0) {
            tokenURIIndex = minURI;
            minURI = minURI + _quantity;
        } else {
            tokenURIIndex = maxURI;
            maxURI = maxURI - _quantity;
        }
        for (uint256 i = 0; i < _quantity; i++) {
            uint256 vitals;
            if (vitalsProb > tokenCounter) {
                vitals = 0;
            } else {
                vitals = 1;
            }
            _safeMint(_rescuer, tokenCounter);
            _setTokenURI(
                tokenCounter,
                string(
                    abi.encodePacked(
                        "https://ipfs.io/ipfs/QmP39ZqmPjdk7DfnNoPBTU1TpfoDocPP8DjBPreutyS9Zw/",
                        uint2str(tokenURIIndex),
                        "%20-%20",
                        uint2str(vitals),
                        ".json"
                    )
                )
            );
            if (tokenURIBinary == 0) {
                tokenURIIndex = tokenURIIndex + 1;
            } else {
                tokenURIIndex = tokenURIIndex - 1;
            }
            tokenCounter = tokenCounter + 1;
        }
    }

    function withdrawBalance() public onlyOwner {
        payable(msg.sender).transfer(address(this).balance);
    }
}