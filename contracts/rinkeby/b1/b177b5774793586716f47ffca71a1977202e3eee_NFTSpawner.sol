/**
 *Submitted for verification at Etherscan.io on 2017-11-28
 */

pragma solidity ^0.4.11;

import "./HasNoEther.sol";

import "./ECVerify.sol";
import "./IERC721Base.sol";
import "./GeneScience.sol";
import "./NFTCore.sol";

interface IERC20 {
    function transfer(address to, uint256 value) external returns (bool);

    function approve(address spender, uint256 value) external returns (bool);

    function mint(address account, uint256 value) external returns (bool);

    function burn(address account, uint256 value) external returns (bool);

    function transferFrom(
        address from,
        address to,
        uint256 value
    ) external returns (bool);

    function totalSupply() external view returns (uint256);

    function balanceOf(address who) external view returns (uint256);

    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
}

contract NFTSpawnerDependency is Ownable {
    address public whitelistSetterAddress;

    constructor() public {
        whitelistSetterAddress = msg.sender;
    }

    modifier onlyWhitelistSetter() {
        require(msg.sender == whitelistSetterAddress);
        _;
    }

    function setWhitelistSetter(address _newSetter) external onlyOwner {
        whitelistSetterAddress = _newSetter;
    }
}

contract NFTSpawner is HasNoEther, GeneScience, NFTSpawnerDependency {
    using ECVerify for bytes32;
    event breedNFTsed(uint256 indexed _matronId, uint256 indexed _sireId);

    constructor() public {
        coreContract = NFTCore(
            address(0x3d394d6757f86bcee20f87b313ce3a83af05be90)
        );
        smoothLovePotion = IERC20(0xfdacf9afc5719c573423bae7faa902d191362823);
        axieInfinityShardContract = IERC20(
            0x95869ad74def71e258ec3300c4fe3a9d86fb3c22
        );
    }

    NFTCore public coreContract;
    IERC20 public smoothLovePotion;
    IERC20 public axieInfinityShardContract;

    function breedNFTs(uint256 _matronId, uint256 _sireId)
        external
        returns (uint256)
    {
        require(coreContract != address(0), "coreContract != address(0)");
        require(
            smoothLovePotion != address(0),
            "smoothLovePotion != address(0)"
        );
        require(
            axieInfinityShardContract != address(0),
            "axieInfinityShardContract != address(0)"
        );
        uint256 matronId = _matronId;
        uint256 sireId = _sireId;
        require(
            coreContract.ownerOf(matronId) == msg.sender,
            "coreContract.ownerOf(matronId) == msg.sender"
        );
        require(
            coreContract.ownerOf(sireId) == msg.sender,
            "coreContract.ownerOf(sireId) == msg.sender"
        );
        require(_isValidMatingPair(matronId, sireId), "_isValidMatingPair");
        {
            uint256 matronbreedCount;
            uint256 sirebreedCount;
            {
                (, , , , matronbreedCount) = coreContract.getNFT(matronId);
                (, , , , sirebreedCount) = coreContract.getNFT(sireId);
            }

            require(matronbreedCount < 7, "matron.breedCount < 7");
            require(sirebreedCount < 7, "sire.breedCount < 7");
            uint256 slpcount = 0;
            if (matronbreedCount == 0) {
                slpcount += 150;
            } else if (matronbreedCount == 1) {
                slpcount += 300;
            } else if (matronbreedCount == 2) {
                slpcount += 450;
            } else if (matronbreedCount == 3) {
                slpcount += 750;
            } else if (matronbreedCount == 4) {
                slpcount += 1200;
            } else if (matronbreedCount == 5) {
                slpcount += 1950;
            } else if (matronbreedCount == 6) {
                slpcount += 3150;
            }
            if (sirebreedCount == 0) {
                slpcount += 150;
            } else if (sirebreedCount == 1) {
                slpcount += 300;
            } else if (sirebreedCount == 2) {
                slpcount += 450;
            } else if (sirebreedCount == 3) {
                slpcount += 750;
            } else if (sirebreedCount == 4) {
                slpcount += 1200;
            } else if (sirebreedCount == 5) {
                slpcount += 1950;
            } else if (sirebreedCount == 6) {
                slpcount += 3150;
            }
            require(
                smoothLovePotion.balanceOf(msg.sender) >= slpcount,
                "SLP不足"
            );
            require(
                axieInfinityShardContract.balanceOf(msg.sender) >= 2,
                "AXS不足"
            );
            smoothLovePotion.burn(msg.sender, slpcount);
            axieInfinityShardContract.burn(msg.sender, 2);
        }
        emit breedNFTsed(matronId, sireId);
        return coreContract.spawnNFTBreed(0, msg.sender, matronId, sireId);
    }

    function verifySignatures(bytes32 _hash, bytes memory _signature)
        public
        view
        returns (bool)
    {
        return whitelistSetterAddress == _hash.recover(_signature);
    }

    function batchGrowNFTggsToAdult(
        uint256 _axieId,
        uint256 _seed,
        bytes memory _signature
    ) public returns (uint256) {
        require(coreContract != address(0), "coreContract != address(0)");
        bytes32 _hash = keccak256(
            abi.encodePacked("batchGrowNFTggsToAdults", _axieId, _seed)
        );
        require(verifySignatures(_hash, _signature));

        uint256 seed = _seed;
        uint256 matronId;
        uint256 sireId;
        uint256 genes;
        (genes, , matronId, sireId, ) = coreContract.getNFT(_axieId);
        require(genes == uint256(0), "genes == uint256(0)");
        uint256 matrongenes;
        uint256 siregenes;
        {
            (matrongenes, , , , ) = coreContract.getNFT(matronId);
            (siregenes, , , , ) = coreContract.getNFT(sireId);
        }
        uint256 childGenes = mixGenes(matrongenes, siregenes, seed);
        coreContract.rebirthNFT(_axieId, childGenes);
    }

    function buyInitNFT(
        uint256 buyPrice,
        uint256 genes,
        uint256 endingAt,
        bytes memory _signature
    ) public payable returns (bytes32) {
        require(msg.value >= buyPrice, "msg.value < buyPrice");
        require(endingAt >= now, "endingAt < now");
        if (msg.value > buyPrice) {
            uint256 _bidExcess = msg.value - buyPrice;
            msg.sender.transfer(_bidExcess);
        }
        bytes32 _hash = keccak256(
            abi.encodePacked("buyInitNFT", buyPrice, genes, endingAt)
        );
        require(
            verifySignatures(_hash, _signature),
            "verifySignatures(_hash, _signature)"
        );
        coreContract.spawnNFT(genes, msg.sender);
        return _hash;
    }

    function getTime() public view returns (uint256) {
        return now;
    }

    function _isValidMatingPair(uint256 _matronId, uint256 _sireId)
        private
        view
        returns (bool)
    {
        // A Kitty can't breed with itself!
        if (_matronId == _sireId) {
            return false;
        }

        uint256 _matronmatronId;
        uint256 _matronsireId;
        uint256 _sirematronId;
        uint256 _siresireId;
        (, , _matronmatronId, _matronsireId, ) = coreContract.getNFT(_matronId);
        (, , _sirematronId, _siresireId, ) = coreContract.getNFT(_sireId);

        // Kitties can't breed with their parents.
        if (_matronmatronId == _sireId || _matronsireId == _sireId) {
            return false;
        }
        if (_sirematronId == _matronId || _siresireId == _matronId) {
            return false;
        }

        // We can short circuit the sibling check (below) if either cat is
        // gen zero (has a matron ID of zero).
        if (_sirematronId == 0 || _matronmatronId == 0) {
            return true;
        }

        // Kitties can't breed with full or half siblings.
        if (
            _sirematronId == _matronmatronId || _sirematronId == _matronsireId
        ) {
            return false;
        }
        if (_siresireId == _matronmatronId || _siresireId == _matronsireId) {
            return false;
        }

        // Everything seems cool! Let's get DTF.
        return true;
    }
}