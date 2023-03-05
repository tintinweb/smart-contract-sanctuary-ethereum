pragma solidity ^0.8.12;

import "erc721a/contracts/ERC721A.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./cosmic-lib.sol";

contract PlanetAddresses is ERC721A, Ownable {
    mapping(uint256 => address) private pData;
    bool public saleStarted;
    uint16 private constant MAX_MINT = 2023;
    uint160 private constant PRICE = 0.0069 ether;

    constructor() ERC721A("Planets on Chain", "PLANETADDR"){
        saleStarted = false;
    }

    function mint() external payable{
        require(saleStarted, "Sale not started");
        require(_totalMinted() <= MAX_MINT, "Max mint reached");
        require(_numberMinted(msg.sender) < 1, "1 mint only sadly");
        require(msg.value == PRICE, "Wrong amount paid");

        pData[_nextTokenId()] = msg.sender;
        
        _mint(msg.sender, 1);
    }    

    function hasMinted() external view returns (bool){
        return _numberMinted(msg.sender) > 0;
    }

    function setSaleStarted(bool _saleStarted) external onlyOwner {
        saleStarted = _saleStarted;
    }

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        string memory result;

        bytes memory p = abi.encodePacked(pData[tokenId]);

        return CosmicSVGRenderer.render(p);
    }

    function withdraw() external onlyOwner {
        payable(owner()).transfer(address(this).balance);
    }
}

pragma solidity ^0.8.12;

library CosmicSVGRenderer {
    function render(bytes memory p) public pure returns (string memory) {
        string memory result;
        result = string(abi.encodePacked(
            'data:application/json,{"name":"Planet Name: ',
            toString(p),
            '", "description": "A little planet generated from the minters address, completely on-chain","image":"data:image/svg+xml,',
            header,
            buildStars(p),
            starsEnd,
            rgbToString(uint8(p[13]), uint8(p[14]), uint8(p[15]), ","),
            gradientMiddle,
            rgbToString(uint8(p[16]), uint8(p[17]), uint8(p[18]), ","),
            gradientEnd
        ));

        result = string(abi.encodePacked(
            result,
            planetStart, // planetStart
            rgbToString(uint8(p[0]), uint8(p[1]), uint8(p[2]), ","), //planetRGB
            planetEnd, // planetEnd
            rgbToString(uint8(p[7]), uint8(p[8]), uint8(p[9]), " "), // shadowRGB
            planetStyleEnd, // planetStyleEnd
            rgbToString(uint8(p[3]), uint8(p[4]), uint8(p[5]), " "), // gasRGB
            gasStyleEnd // gasStyleEnd
        ));

        if (uint8(p[6]) > 175) {
            result = string.concat(result, dog);
        }

        if (uint8(p[15]) < 40) {
            result = string(abi.encodePacked(
                result,
                bigPlanet,
                moon,
                string(abi.encodePacked(
                    "translate(",
                    toString(uint8(p[10])), 
                    ",", 
                    toString(uint8(p[11])), 
                    ") scale(0.25) rotate(", 
                    toString(uint8(p[12])), 
                    ")"
                )),
                moonEnd,
                end
            ));
        } else {
            result = string(abi.encodePacked(
                result,
                moon,
                string(abi.encodePacked(
                    "translate(",
                    toString(uint8(p[10])), 
                    ",", 
                    toString(uint8(p[11])), 
                    ") scale(0.25) rotate(", 
                    toString(uint8(p[12])), 
                    ")"
                )),
                moonEnd,
                bigPlanet,
                end
            ));
        }
        
        return result;
    }


    function rgbToString(uint8 r, uint8 g, uint8 b, string memory delim) internal pure returns (string memory) {
        return string(abi.encodePacked(
            toString(r),
            delim,
            toString(g),
            delim,
            toString(b)
        ));
    }

    function toString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }

    function toString(bytes memory data) internal pure returns (string memory) {
        bytes memory alphabet = "0123456789abcdef";

        bytes memory str = new bytes(2 + data.length * 2);
        str[0] = "0";
        str[1] = "x";
        for (uint i = 0; i < 4; i++) {
            str[2+i*2] = alphabet[uint(uint8(data[i] >> 4))];
            str[3+i*2] = alphabet[uint(uint8(data[i] & 0x0f))];
        }
        return string(str);
    }

    function buildStars(bytes memory data) internal pure returns (string memory) {
        string memory stars = "";
        for (uint8 i = 0; i < 20; i = i+2) {     
            stars = string.concat(stars, string(abi.encodePacked(
                "<use href='#a' x='", 
                toString(uint8(data[i])),
                "' y='",
                toString(uint8(data[i+1])),
                "'/>"
            )));

            stars = string.concat(stars, string(abi.encodePacked(
                "<use href='#a' x='", 
                toString(uint16(uint8(data[i]))*2),
                "' y='",
                toString(uint16(uint8(data[i+1]))*2),
                "'/>"
            )));  
        }

        return stars;
    }

    string public constant header = "<svg width='512' height='512' style='background: #111' xmlns='http://www.w3.org/2000/svg' xmlns:xlink='http://www.w3.org/1999/xlink'><defs><path id='a' d='m0 .5 1.736 3.104L.391.312 3.9.89.487-.111l2.64-2.383L.217-.45 0-4-.217-.45l-2.91-2.044 2.64 2.383L-3.9.89-.391.312l-1.345 3.292L0 .5'/><g id='b'>";
    string public constant starsEnd = "</g><linearGradient id='gradient-fill' x1='0' y1='0' x2='512' y2='512' gradientUnits='userSpaceOnUse'><stop offset='0' stop-color='rgba(";
    string public constant gradientMiddle = ", .45)' /><stop offset='1' stop-color='rgba("; 
    string public constant gradientEnd = ", .45)' /></linearGradient>";
    string public constant planetStyleEnd = ");}.gas{fill:rgb(";
    string public constant gasStyleEnd = ");}.moon{filter:sepia(50%) hue-rotate(86deg););</style>";
    string public constant planetStart = "<g id='planet' transform='matrix(.5 0 0 .5 125 125)'><circle class='planet' style='filter:drop-shadow(1px 1px 72px rgba(";
    string public constant planetEnd = ",.6))' cx='256.002' cy='256.002' r='248'/><path class='gas' d='M336 24.001s-91.283 37.085-136-8c0 0-105.272 20.879-104 63.999 0 0 78.315 51.896 248 32 0 0 77.619-18.997 136 40.001-.001-.001-54.607-115.12-144-128z'/><path class='planet' d='M504 256c0 136.966-111.034 248-248 248S8 392.966 8 256'/><path class='gas' d='M343.999 480c0 13.255-58.745 24-71.999 24s-72-2.745-72-16c0-13.255 58.745-24 71.999-24s72 2.745 72 16zM9.55 265.402s-13.237 34.194 44.92 135.805c0 0 91.346-58.303 217.53-1.207s207.999-32 207.999-32 34.534-83.577 23.671-136.027c0 0-87.118 58.661-231.67.027 0 0-174.922-91.917-262.45 33.402z'/><path style='fill:#1d1d1b' d='m495.468 165.146.004-.002c-.014-.036-.044-.114-.085-.212-12.676-33.361-32.378-63.961-58.369-89.952C388.668 26.629 324.381 0 256 0S123.334 26.629 74.981 74.981C26.629 123.334 0 187.62 0 256s26.629 132.668 74.981 181.019C123.334 485.371 187.62 512 256 512s132.668-26.629 181.019-74.981C485.371 388.666 512 324.38 512 256c0-31.545-5.68-62.214-16.532-90.854zm-39.312-41.7c-35.507-21.562-84.358-28.08-145.289-19.366-73.729 10.546-129.05-.451-162.476-11.532-21.695-7.192-37.224-15.345-46.235-20.761 26.063-21.843 56.065-37.67 88.301-46.765 5.913 4.395 18.466 12.353 37.567 17.597 10.396 2.854 23.721 5.125 39.803 5.125 20.861 0 46.375-3.844 76.131-15.169C374.23 44.484 402.01 62.6 425.703 86.294a242.305 242.305 0 0 1 30.453 37.152zm-137.59-99.238c-38.198 10.893-66.932 8.129-85.317 3.25-8.204-2.177-15.02-4.928-20.43-7.593A242.715 242.715 0 0 1 256 16c21.424 0 42.414 2.804 62.566 8.208zM86.294 86.294a253.772 253.772 0 0 1 3.446-3.364c8.881 5.719 26.533 15.736 52.75 24.516 63.767 21.359 127.992 18.572 170.642 12.472 39.974-5.717 96.088-7.189 136.425 18.255 18.77 11.841 28.341 26.3 30.874 32.459 7.148 18.814 11.901 38.566 14.116 58.881-8.344 6.187-25.807 15.449-51.559 20.11-64.961 11.757-140.217-11.461-191.91-33.008-43.652-18.195-83.884-26.941-119.59-25.956-29.03.79-55.141 7.945-77.608 21.265a141.412 141.412 0 0 0-37.6 32.384c2.847-59.714 27.451-115.45 70.014-158.014zM205.02 490.59c6.296-3.603 14.561-7.493 24.862-10.665 37.083-11.42 76.687-6.511 108.043 1.784C312.01 491.097 284.383 496 256.001 496a242.103 242.103 0 0 1-50.981-5.41zm220.686-64.884c-19.165 19.164-41.007 34.672-64.673 46.209-35.764-11.869-88.056-22.43-137.035-6.915-19.582 6.203-32.664 14.709-39.67 20.154-36.607-11.401-70.149-31.564-98.034-59.449a244.21 244.21 0 0 1-19.651-22.189c22.672-10.71 101.945-40.83 202.1 3.791 33.337 14.853 63.342 20.112 89.126 20.112 25.528 0 46.918-5.157 63.293-11.266a180.791 180.791 0 0 0 22.043-9.954 243.672 243.672 0 0 1-17.499 19.507zm41.076-54.743-.538-.519c-.179.185-18.204 18.607-50.673 30.719-43.809 16.343-91.018 13.494-140.316-8.47-65.728-29.283-122.761-27.705-159.03-21.226-29.38 5.249-50.062 14.332-59.158 18.895-23.639-34.843-37.601-75.206-40.492-117.737 3.843-7.463 17.279-30.226 45.465-46.937 20.096-11.914 43.608-18.318 69.883-19.034 33.436-.908 71.447 7.411 112.998 24.73 43.245 18.026 83.891 29.681 120.807 34.639 29.832 4.007 57.355 3.68 81.805-.968 22.427-4.265 38.239-11.419 48.31-17.355.093 2.761.157 5.526.157 8.302 0 40.835-10.146 80.108-29.218 114.961z'/></g></defs><g class='box'><rect width='100%' height='100%' fill='url(#gradient-fill)'/><use href='#b' style='fill:#bfbf40;transform:scale(.8) rotate(200deg) translate(-350 -50);transform-origin:center center'/><style>.planet{ fill: rgb(";
    string public constant bigPlanet = "<use xlink:href='#planet' />";
    string public constant moon = "<use xlink:href='#planet' x='0' y='0' transform='";
    string public constant moonEnd = "' class='moon' />";
    string public constant end = '</g></svg>"}';
    string public constant dog = "<path style='fill:#ffd0a1' d='M361.667 276.76c0 9.387-.853 39.253-7.68 58.88l.853 2.56c-27.307 11.947-63.147 23.04-103.253 23.04-40.107 0-75.947-11.093-103.253-23.04l.853-1.707c-8.533-21.333-8.533-51.2-8.533-60.587 0-23.893 2.56-46.933 6.827-69.12 7.68-37.547 22.187-71.68 43.52-93.013 16.213-16.213 35.84-25.6 60.587-25.6s44.373 9.387 60.587 25.6c22.187 22.187 36.693 56.32 44.373 94.72 3.412 22.187 5.119 45.227 5.119 68.267' transform='matrix(.1 0 0 .1 200.1 100.1)'/><path style='fill:#ecf4f7' d='M353.987 335.64c7.68-20.48 7.68-49.493 7.68-58.88 0-23.04-1.707-46.08-5.973-67.413 17.92 11.947 34.987 7.68 34.987 7.68 8.533 0 13.653-15.36 13.653-34.133 0-9.387-11.947-40.107-17.067-51.2C370.2 97.56 344.6 89.027 327.533 89.027s-16.213 25.6-16.213 25.6c-16.213-16.213-35.84-25.6-60.587-25.6s-44.373 9.387-60.587 25.6c0 0 .853-25.6-16.213-25.6-17.067 0-42.667 8.533-59.733 42.667-5.12 11.093-17.067 41.813-17.067 51.2 0 18.773 5.12 34.133 13.653 34.133 0 0 14.507 6.827 34.133-9.387h.853c-4.267 22.187-6.827 45.227-6.827 69.12 0 9.387 0 39.253 8.533 60.587l-.853 1.707c-30.72-13.653-50.347-28.16-50.347-28.16s-29.013-22.187-57.173-58.88c-1.707-11.093-2.56-23.04-2.56-34.987 0-117.76 95.573-213.333 213.333-213.333s213.333 95.573 213.333 213.333c0 11.947-.853 23.893-2.56 34.987h-.851c-22.187 36.693-56.32 58.88-56.32 58.88s-19.627 14.507-50.347 28.16l.854-3.414zM250.733 481.56v17.067H3.267c0-42.667 51.2-68.267 51.2-68.267s15.36-4.267 34.133-4.267c44.373 34.987 100.693 55.467 162.133 55.467zM498.2 498.627H250.733V481.56c61.44 0 117.76-20.48 162.133-55.467 24.747 0 34.133 4.267 34.133 4.267s51.201 25.6 51.201 68.267z' transform='matrix(.1 0 0 .1 200.1 100.1)'/><path style='fill:#ffe079' d='M284.867 191.427c5.12 0 8.533 4.267 8.533 8.533s-3.413 8.533-8.533 8.533c-5.12 0-8.533-4.267-8.533-8.533s3.413-8.533 8.533-8.533zm-68.267 0c5.12 0 8.533 4.267 8.533 8.533s-3.413 8.533-8.533 8.533c-5.12 0-8.533-4.267-8.533-8.533s3.413-8.533 8.533-8.533z' transform='matrix(.1 0 0 .1 200.1 100.1)'/><path style='fill:#ffd0a1' d='M190.147 114.627c-22.187 21.333-35.84 55.467-43.52 93.013h-.853c-19.627 16.213-34.133 9.387-34.133 9.387-8.533 0-13.653-15.36-13.653-34.133 0-9.387 11.947-40.107 17.067-51.2 17.067-34.133 42.667-42.667 59.733-42.667s15.359 25.6 15.359 25.6zm214.186 68.266c0 18.773-5.12 34.133-13.653 34.133 0 0-17.067 4.267-34.987-7.68-7.68-38.4-22.187-72.533-44.373-94.72 0 0-.853-25.6 16.213-25.6 17.067 0 42.667 8.533 59.733 42.667 5.121 11.094 17.067 41.814 17.067 51.2z' transform='matrix(.1 0 0 .1 200.1 100.1)'/><path style='fill:#aab1ba' d='M412.867 355.267v70.827C367.64 461.08 312.173 481.56 250.733 481.56S132.973 461.08 88.6 426.093V356.12c39.253 46.08 97.28 75.093 162.133 75.093s122.88-29.866 162.134-75.946' transform='matrix(.1 0 0 .1 200.1 100.1)'/><path style='fill:#aab1ba' d='M461.507 252.013c-6.827 39.253-23.893 75.093-48.64 103.253-39.253 46.08-97.28 75.093-162.133 75.093S127.853 401.347 88.6 355.267c-24.747-29.013-41.813-64.853-48.64-104.107 28.16 37.547 57.173 58.88 57.173 58.88s19.627 14.507 50.347 28.16c27.307 11.947 63.147 23.04 103.253 23.04 40.107 0 75.947-11.093 103.253-23.04 30.72-13.653 50.347-28.16 50.347-28.16s34.134-21.333 57.174-58.027z' transform='matrix(.1 0 0 .1 200.1 100.1)'/><path style='fill:#ae938d' d='M250.733 259.693c14.507 0 25.6 7.68 25.6 17.067s-11.093 17.067-25.6 17.067c-14.507 0-25.6-7.68-25.6-17.067s11.094-17.067 25.6-17.067' transform='matrix(.1 0 0 .1 200.1 100.1)'/><path style='fill:#80d6fa' d='M54.467 20.76c0 9.387-7.68 17.067-17.067 17.067s-17.067-7.68-17.067-17.067S28.013 3.693 37.4 3.693s17.067 7.68 17.067 17.067' transform='matrix(.1 0 0 .1 200.1 100.1)'/><path style='fill:#51565f' d='M499.2 503.893c-2.56 0-4.267-1.707-4.267-4.267 0-39.253-48.64-64-48.64-64.853-1.707-.853-2.56-3.413-1.707-5.973.853-1.707 3.413-2.56 5.973-1.707s53.76 27.307 53.76 71.68c-.852 3.414-2.559 5.12-5.119 5.12zm-494.933 0c-2.56 0-4.267-1.707-4.267-4.267 0-44.373 51.2-70.827 53.76-71.68 1.707-.853 4.267 0 5.973 1.707.853 1.707 0 4.267-1.707 5.973-.853 0-48.64 24.747-48.64 64.853-.853 1.708-2.559 3.414-5.119 3.414zm247.466-17.066c-60.587 0-116.907-19.627-164.693-56.32-.853-.853-1.707-1.707-1.707-3.413v-69.12c-31.573-37.547-51.2-87.04-51.2-139.947V42.24C24.747 40.533 17.067 32 17.067 21.76 17.067 9.813 26.454.427 38.4.427S59.733 9.813 59.733 21.76c0 10.24-7.68 18.773-17.067 20.48v115.2C69.12 66.987 152.747.427 251.733.427c120.32 0 217.6 97.28 217.6 217.6 0 52.907-19.627 102.4-51.2 139.947v69.12c0 1.707-.853 2.56-1.707 3.413-47.786 36.693-104.106 56.32-164.693 56.32zM93.867 424.533c46.08 34.987 99.84 53.76 157.867 53.76S363.52 459.52 409.6 424.533V367.36c-40.107 41.813-95.573 68.267-157.867 68.267s-117.76-26.453-157.867-68.267v57.173zM251.733 8.96c-115.2 0-209.067 93.867-209.067 209.067s93.867 209.067 209.067 209.067c63.147 0 119.467-28.16 157.867-72.533 0-.853.853-2.56 2.56-2.56 30.72-36.693 48.64-82.773 48.64-133.973C460.8 102.827 366.933 8.96 251.733 8.96zM38.4 8.96c-6.827 0-12.8 5.973-12.8 12.8s5.973 12.8 12.8 12.8 12.8-5.973 12.8-12.8-5.973-12.8-12.8-12.8zm213.333 358.4c-86.187 0-153.6-50.347-156.16-52.053-1.707-1.707-2.56-4.267-.853-5.973 1.707-1.707 4.267-2.56 5.973-.853.853.853 68.267 50.347 151.04 50.347s150.187-49.493 151.04-50.347c1.707-1.707 4.267-.853 5.973.853 1.707 1.707.853 4.267-.853 5.973-2.56 1.706-69.973 52.053-156.16 52.053zm34.134-42.667c-13.653 0-27.307-5.12-34.133-15.36-6.827 10.24-20.48 15.36-34.133 15.36-2.56 0-4.267-1.707-4.267-4.267 0-2.56 1.707-4.267 4.267-4.267 12.8 0 27.307-5.12 29.867-17.067-14.507-1.707-25.6-10.24-25.6-21.333 0-11.947 12.8-21.333 29.867-21.333s29.867 9.387 29.867 21.333c0 11.093-11.093 19.627-25.6 21.333 2.56 11.947 16.213 17.067 29.867 17.067 2.56 0 4.267 1.707 4.267 4.267-.003 2.561-1.709 4.267-4.269 4.267zm-34.134-59.733c-11.947 0-21.333 5.973-21.333 12.8s9.387 12.8 21.333 12.8c11.947 0 21.333-5.973 21.333-12.8s-9.386-12.8-21.333-12.8zm109.227 43.52c-2.56 0-4.267-2.56-4.267-5.12.853-7.68 1.707-16.213 1.707-25.6 0-91.307-33.28-183.467-106.667-183.467s-106.667 92.16-106.667 183.467c0 8.533.853 17.067 1.707 24.747 0 2.56-1.707 4.267-3.413 5.12-2.56 0-4.267-1.707-5.12-3.413-.853-7.68-1.707-17.067-1.707-26.453 0-64 16.213-128 50.347-163.84 0-4.267-.853-12.8-5.12-17.067-1.707-1.707-4.267-2.56-6.827-2.56-11.093 0-37.547 4.267-56.32 40.107-5.12 10.24-16.213 40.96-16.213 49.493 0 19.627 5.973 29.867 9.387 29.867 2.56 0 4.267 1.707 4.267 4.267s-1.707 4.267-4.267 4.267c-11.093 0-17.92-15.36-17.92-38.4 0-11.093 12.8-42.667 17.92-52.907 20.48-40.96 51.2-45.227 63.147-45.227 5.12 0 9.387 1.707 12.8 5.12 4.267 4.267 5.973 10.24 6.827 15.36 15.36-12.8 34.987-21.333 57.173-21.333 22.187 0 41.813 7.68 57.173 21.333.853-5.12 2.56-11.093 6.827-15.36 3.413-3.413 7.68-5.12 12.8-5.12 11.947 0 43.52 4.267 63.147 45.227 5.12 10.24 17.92 41.813 17.92 52.907 0 23.04-6.827 38.4-17.92 38.4-2.56 0-4.267-1.707-4.267-4.267s1.707-4.267 4.267-4.267c4.267 0 9.387-10.24 9.387-29.867 0-8.533-11.093-38.4-16.213-49.493-17.92-36.693-45.227-40.107-56.32-40.107-2.56 0-5.12.853-6.827 2.56-4.267 4.267-5.12 12.8-5.12 17.067 34.133 35.84 50.347 99.84 50.347 163.84 0 10.24-.853 18.773-1.707 27.307-.001 1.705-1.708 3.412-4.268 3.412zm-75.093-94.72c-6.827 0-12.8-5.973-12.8-12.8s5.973-12.8 12.8-12.8c6.827 0 12.8 5.973 12.8 12.8s-5.974 12.8-12.8 12.8zm0-17.067c-2.56 0-4.267 1.707-4.267 4.267s1.707 4.267 4.267 4.267 4.267-1.707 4.267-4.267-1.707-4.267-4.267-4.267zM217.6 213.76c-6.827 0-12.8-5.973-12.8-12.8s5.973-12.8 12.8-12.8c6.827 0 12.8 5.973 12.8 12.8s-5.973 12.8-12.8 12.8zm0-17.067c-2.56 0-4.267 1.707-4.267 4.267s1.707 4.267 4.267 4.267 4.267-1.707 4.267-4.267-1.707-4.267-4.267-4.267z' transform='matrix(.1 0 0 .1 200 100)'/>";
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
// ERC721A Contracts v4.2.3
// Creator: Chiru Labs

pragma solidity ^0.8.4;

import './IERC721A.sol';

/**
 * @dev Interface of ERC721 token receiver.
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
 * @title ERC721A
 *
 * @dev Implementation of the [ERC721](https://eips.ethereum.org/EIPS/eip-721)
 * Non-Fungible Token Standard, including the Metadata extension.
 * Optimized for lower gas during batch mints.
 *
 * Token IDs are minted in sequential order (e.g. 0, 1, 2, 3, ...)
 * starting from `_startTokenId()`.
 *
 * Assumptions:
 *
 * - An owner cannot have more than 2**64 - 1 (max value of uint64) of supply.
 * - The maximum token ID cannot exceed 2**256 - 1 (max value of uint256).
 */
contract ERC721A is IERC721A {
    // Bypass for a `--via-ir` bug (https://github.com/chiru-labs/ERC721A/pull/364).
    struct TokenApprovalRef {
        address value;
    }

    // =============================================================
    //                           CONSTANTS
    // =============================================================

    // Mask of an entry in packed address data.
    uint256 private constant _BITMASK_ADDRESS_DATA_ENTRY = (1 << 64) - 1;

    // The bit position of `numberMinted` in packed address data.
    uint256 private constant _BITPOS_NUMBER_MINTED = 64;

    // The bit position of `numberBurned` in packed address data.
    uint256 private constant _BITPOS_NUMBER_BURNED = 128;

    // The bit position of `aux` in packed address data.
    uint256 private constant _BITPOS_AUX = 192;

    // Mask of all 256 bits in packed address data except the 64 bits for `aux`.
    uint256 private constant _BITMASK_AUX_COMPLEMENT = (1 << 192) - 1;

    // The bit position of `startTimestamp` in packed ownership.
    uint256 private constant _BITPOS_START_TIMESTAMP = 160;

    // The bit mask of the `burned` bit in packed ownership.
    uint256 private constant _BITMASK_BURNED = 1 << 224;

    // The bit position of the `nextInitialized` bit in packed ownership.
    uint256 private constant _BITPOS_NEXT_INITIALIZED = 225;

    // The bit mask of the `nextInitialized` bit in packed ownership.
    uint256 private constant _BITMASK_NEXT_INITIALIZED = 1 << 225;

    // The bit position of `extraData` in packed ownership.
    uint256 private constant _BITPOS_EXTRA_DATA = 232;

    // Mask of all 256 bits in a packed ownership except the 24 bits for `extraData`.
    uint256 private constant _BITMASK_EXTRA_DATA_COMPLEMENT = (1 << 232) - 1;

    // The mask of the lower 160 bits for addresses.
    uint256 private constant _BITMASK_ADDRESS = (1 << 160) - 1;

    // The maximum `quantity` that can be minted with {_mintERC2309}.
    // This limit is to prevent overflows on the address data entries.
    // For a limit of 5000, a total of 3.689e15 calls to {_mintERC2309}
    // is required to cause an overflow, which is unrealistic.
    uint256 private constant _MAX_MINT_ERC2309_QUANTITY_LIMIT = 5000;

    // The `Transfer` event signature is given by:
    // `keccak256(bytes("Transfer(address,address,uint256)"))`.
    bytes32 private constant _TRANSFER_EVENT_SIGNATURE =
        0xddf252ad1be2c89b69c2b068fc378daa952ba7f163c4a11628f55a4df523b3ef;

    // =============================================================
    //                            STORAGE
    // =============================================================

    // The next token ID to be minted.
    uint256 private _currentIndex;

    // The number of tokens burned.
    uint256 private _burnCounter;

    // Token name
    string private _name;

    // Token symbol
    string private _symbol;

    // Mapping from token ID to ownership details
    // An empty struct value does not necessarily mean the token is unowned.
    // See {_packedOwnershipOf} implementation for details.
    //
    // Bits Layout:
    // - [0..159]   `addr`
    // - [160..223] `startTimestamp`
    // - [224]      `burned`
    // - [225]      `nextInitialized`
    // - [232..255] `extraData`
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
    mapping(uint256 => TokenApprovalRef) private _tokenApprovals;

    // Mapping from owner to operator approvals
    mapping(address => mapping(address => bool)) private _operatorApprovals;

    // =============================================================
    //                          CONSTRUCTOR
    // =============================================================

    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
        _currentIndex = _startTokenId();
    }

    // =============================================================
    //                   TOKEN COUNTING OPERATIONS
    // =============================================================

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
    function _nextTokenId() internal view virtual returns (uint256) {
        return _currentIndex;
    }

    /**
     * @dev Returns the total number of tokens in existence.
     * Burned tokens will reduce the count.
     * To get the total number of tokens minted, please see {_totalMinted}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        // Counter underflow is impossible as _burnCounter cannot be incremented
        // more than `_currentIndex - _startTokenId()` times.
        unchecked {
            return _currentIndex - _burnCounter - _startTokenId();
        }
    }

    /**
     * @dev Returns the total amount of tokens minted in the contract.
     */
    function _totalMinted() internal view virtual returns (uint256) {
        // Counter underflow is impossible as `_currentIndex` does not decrement,
        // and it is initialized to `_startTokenId()`.
        unchecked {
            return _currentIndex - _startTokenId();
        }
    }

    /**
     * @dev Returns the total number of tokens burned.
     */
    function _totalBurned() internal view virtual returns (uint256) {
        return _burnCounter;
    }

    // =============================================================
    //                    ADDRESS DATA OPERATIONS
    // =============================================================

    /**
     * @dev Returns the number of tokens in `owner`'s account.
     */
    function balanceOf(address owner) public view virtual override returns (uint256) {
        if (owner == address(0)) revert BalanceQueryForZeroAddress();
        return _packedAddressData[owner] & _BITMASK_ADDRESS_DATA_ENTRY;
    }

    /**
     * Returns the number of tokens minted by `owner`.
     */
    function _numberMinted(address owner) internal view returns (uint256) {
        return (_packedAddressData[owner] >> _BITPOS_NUMBER_MINTED) & _BITMASK_ADDRESS_DATA_ENTRY;
    }

    /**
     * Returns the number of tokens burned by or on behalf of `owner`.
     */
    function _numberBurned(address owner) internal view returns (uint256) {
        return (_packedAddressData[owner] >> _BITPOS_NUMBER_BURNED) & _BITMASK_ADDRESS_DATA_ENTRY;
    }

    /**
     * Returns the auxiliary data for `owner`. (e.g. number of whitelist mint slots used).
     */
    function _getAux(address owner) internal view returns (uint64) {
        return uint64(_packedAddressData[owner] >> _BITPOS_AUX);
    }

    /**
     * Sets the auxiliary data for `owner`. (e.g. number of whitelist mint slots used).
     * If there are multiple variables, please pack them into a uint64.
     */
    function _setAux(address owner, uint64 aux) internal virtual {
        uint256 packed = _packedAddressData[owner];
        uint256 auxCasted;
        // Cast `aux` with assembly to avoid redundant masking.
        assembly {
            auxCasted := aux
        }
        packed = (packed & _BITMASK_AUX_COMPLEMENT) | (auxCasted << _BITPOS_AUX);
        _packedAddressData[owner] = packed;
    }

    // =============================================================
    //                            IERC165
    // =============================================================

    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * [EIP section](https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified)
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30000 gas.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        // The interface IDs are constants representing the first 4 bytes
        // of the XOR of all function selectors in the interface.
        // See: [ERC165](https://eips.ethereum.org/EIPS/eip-165)
        // (e.g. `bytes4(i.functionA.selector ^ i.functionB.selector ^ ...)`)
        return
            interfaceId == 0x01ffc9a7 || // ERC165 interface ID for ERC165.
            interfaceId == 0x80ac58cd || // ERC165 interface ID for ERC721.
            interfaceId == 0x5b5e139f; // ERC165 interface ID for ERC721Metadata.
    }

    // =============================================================
    //                        IERC721Metadata
    // =============================================================

    /**
     * @dev Returns the token collection name.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the token collection symbol.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the Uniform Resource Identifier (URI) for `tokenId` token.
     */
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        if (!_exists(tokenId)) revert URIQueryForNonexistentToken();

        string memory baseURI = _baseURI();
        return bytes(baseURI).length != 0 ? string(abi.encodePacked(baseURI, _toString(tokenId))) : '';
    }

    /**
     * @dev Base URI for computing {tokenURI}. If set, the resulting URI for each
     * token will be the concatenation of the `baseURI` and the `tokenId`. Empty
     * by default, it can be overridden in child contracts.
     */
    function _baseURI() internal view virtual returns (string memory) {
        return '';
    }

    // =============================================================
    //                     OWNERSHIPS OPERATIONS
    // =============================================================

    /**
     * @dev Returns the owner of the `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function ownerOf(uint256 tokenId) public view virtual override returns (address) {
        return address(uint160(_packedOwnershipOf(tokenId)));
    }

    /**
     * @dev Gas spent here starts off proportional to the maximum mint batch size.
     * It gradually moves to O(1) as tokens get transferred around over time.
     */
    function _ownershipOf(uint256 tokenId) internal view virtual returns (TokenOwnership memory) {
        return _unpackedOwnership(_packedOwnershipOf(tokenId));
    }

    /**
     * @dev Returns the unpacked `TokenOwnership` struct at `index`.
     */
    function _ownershipAt(uint256 index) internal view virtual returns (TokenOwnership memory) {
        return _unpackedOwnership(_packedOwnerships[index]);
    }

    /**
     * @dev Initializes the ownership slot minted at `index` for efficiency purposes.
     */
    function _initializeOwnershipAt(uint256 index) internal virtual {
        if (_packedOwnerships[index] == 0) {
            _packedOwnerships[index] = _packedOwnershipOf(index);
        }
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
                    if (packed & _BITMASK_BURNED == 0) {
                        // Invariant:
                        // There will always be an initialized ownership slot
                        // (i.e. `ownership.addr != address(0) && ownership.burned == false`)
                        // before an unintialized ownership slot
                        // (i.e. `ownership.addr == address(0) && ownership.burned == false`)
                        // Hence, `curr` will not underflow.
                        //
                        // We can directly compare the packed value.
                        // If the address is zero, packed will be zero.
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
     * @dev Returns the unpacked `TokenOwnership` struct from `packed`.
     */
    function _unpackedOwnership(uint256 packed) private pure returns (TokenOwnership memory ownership) {
        ownership.addr = address(uint160(packed));
        ownership.startTimestamp = uint64(packed >> _BITPOS_START_TIMESTAMP);
        ownership.burned = packed & _BITMASK_BURNED != 0;
        ownership.extraData = uint24(packed >> _BITPOS_EXTRA_DATA);
    }

    /**
     * @dev Packs ownership data into a single uint256.
     */
    function _packOwnershipData(address owner, uint256 flags) private view returns (uint256 result) {
        assembly {
            // Mask `owner` to the lower 160 bits, in case the upper bits somehow aren't clean.
            owner := and(owner, _BITMASK_ADDRESS)
            // `owner | (block.timestamp << _BITPOS_START_TIMESTAMP) | flags`.
            result := or(owner, or(shl(_BITPOS_START_TIMESTAMP, timestamp()), flags))
        }
    }

    /**
     * @dev Returns the `nextInitialized` flag set if `quantity` equals 1.
     */
    function _nextInitializedFlag(uint256 quantity) private pure returns (uint256 result) {
        // For branchless setting of the `nextInitialized` flag.
        assembly {
            // `(quantity == 1) << _BITPOS_NEXT_INITIALIZED`.
            result := shl(_BITPOS_NEXT_INITIALIZED, eq(quantity, 1))
        }
    }

    // =============================================================
    //                      APPROVAL OPERATIONS
    // =============================================================

    /**
     * @dev Gives permission to `to` to transfer `tokenId` token to another account.
     * The approval is cleared when the token is transferred.
     *
     * Only a single account can be approved at a time, so approving the
     * zero address clears previous approvals.
     *
     * Requirements:
     *
     * - The caller must own the token or be an approved operator.
     * - `tokenId` must exist.
     *
     * Emits an {Approval} event.
     */
    function approve(address to, uint256 tokenId) public payable virtual override {
        address owner = ownerOf(tokenId);

        if (_msgSenderERC721A() != owner)
            if (!isApprovedForAll(owner, _msgSenderERC721A())) {
                revert ApprovalCallerNotOwnerNorApproved();
            }

        _tokenApprovals[tokenId].value = to;
        emit Approval(owner, to, tokenId);
    }

    /**
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) public view virtual override returns (address) {
        if (!_exists(tokenId)) revert ApprovalQueryForNonexistentToken();

        return _tokenApprovals[tokenId].value;
    }

    /**
     * @dev Approve or remove `operator` as an operator for the caller.
     * Operators can call {transferFrom} or {safeTransferFrom}
     * for any token owned by the caller.
     *
     * Requirements:
     *
     * - The `operator` cannot be the caller.
     *
     * Emits an {ApprovalForAll} event.
     */
    function setApprovalForAll(address operator, bool approved) public virtual override {
        _operatorApprovals[_msgSenderERC721A()][operator] = approved;
        emit ApprovalForAll(_msgSenderERC721A(), operator, approved);
    }

    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}.
     */
    function isApprovedForAll(address owner, address operator) public view virtual override returns (bool) {
        return _operatorApprovals[owner][operator];
    }

    /**
     * @dev Returns whether `tokenId` exists.
     *
     * Tokens can be managed by their owner or approved accounts via {approve} or {setApprovalForAll}.
     *
     * Tokens start existing when they are minted. See {_mint}.
     */
    function _exists(uint256 tokenId) internal view virtual returns (bool) {
        return
            _startTokenId() <= tokenId &&
            tokenId < _currentIndex && // If within bounds,
            _packedOwnerships[tokenId] & _BITMASK_BURNED == 0; // and not burned.
    }

    /**
     * @dev Returns whether `msgSender` is equal to `approvedAddress` or `owner`.
     */
    function _isSenderApprovedOrOwner(
        address approvedAddress,
        address owner,
        address msgSender
    ) private pure returns (bool result) {
        assembly {
            // Mask `owner` to the lower 160 bits, in case the upper bits somehow aren't clean.
            owner := and(owner, _BITMASK_ADDRESS)
            // Mask `msgSender` to the lower 160 bits, in case the upper bits somehow aren't clean.
            msgSender := and(msgSender, _BITMASK_ADDRESS)
            // `msgSender == owner || msgSender == approvedAddress`.
            result := or(eq(msgSender, owner), eq(msgSender, approvedAddress))
        }
    }

    /**
     * @dev Returns the storage slot and value for the approved address of `tokenId`.
     */
    function _getApprovedSlotAndAddress(uint256 tokenId)
        private
        view
        returns (uint256 approvedAddressSlot, address approvedAddress)
    {
        TokenApprovalRef storage tokenApproval = _tokenApprovals[tokenId];
        // The following is equivalent to `approvedAddress = _tokenApprovals[tokenId].value`.
        assembly {
            approvedAddressSlot := tokenApproval.slot
            approvedAddress := sload(approvedAddressSlot)
        }
    }

    // =============================================================
    //                      TRANSFER OPERATIONS
    // =============================================================

    /**
     * @dev Transfers `tokenId` from `from` to `to`.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token
     * by either {approve} or {setApprovalForAll}.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public payable virtual override {
        uint256 prevOwnershipPacked = _packedOwnershipOf(tokenId);

        if (address(uint160(prevOwnershipPacked)) != from) revert TransferFromIncorrectOwner();

        (uint256 approvedAddressSlot, address approvedAddress) = _getApprovedSlotAndAddress(tokenId);

        // The nested ifs save around 20+ gas over a compound boolean condition.
        if (!_isSenderApprovedOrOwner(approvedAddress, from, _msgSenderERC721A()))
            if (!isApprovedForAll(from, _msgSenderERC721A())) revert TransferCallerNotOwnerNorApproved();

        if (to == address(0)) revert TransferToZeroAddress();

        _beforeTokenTransfers(from, to, tokenId, 1);

        // Clear approvals from the previous owner.
        assembly {
            if approvedAddress {
                // This is equivalent to `delete _tokenApprovals[tokenId]`.
                sstore(approvedAddressSlot, 0)
            }
        }

        // Underflow of the sender's balance is impossible because we check for
        // ownership above and the recipient's balance can't realistically overflow.
        // Counter overflow is incredibly unrealistic as `tokenId` would have to be 2**256.
        unchecked {
            // We can directly increment and decrement the balances.
            --_packedAddressData[from]; // Updates: `balance -= 1`.
            ++_packedAddressData[to]; // Updates: `balance += 1`.

            // Updates:
            // - `address` to the next owner.
            // - `startTimestamp` to the timestamp of transfering.
            // - `burned` to `false`.
            // - `nextInitialized` to `true`.
            _packedOwnerships[tokenId] = _packOwnershipData(
                to,
                _BITMASK_NEXT_INITIALIZED | _nextExtraData(from, to, prevOwnershipPacked)
            );

            // If the next slot may not have been initialized (i.e. `nextInitialized == false`) .
            if (prevOwnershipPacked & _BITMASK_NEXT_INITIALIZED == 0) {
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
     * @dev Equivalent to `safeTransferFrom(from, to, tokenId, '')`.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public payable virtual override {
        safeTransferFrom(from, to, tokenId, '');
    }

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token
     * by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement
     * {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) public payable virtual override {
        transferFrom(from, to, tokenId);
        if (to.code.length != 0)
            if (!_checkContractOnERC721Received(from, to, tokenId, _data)) {
                revert TransferToNonERC721ReceiverImplementer();
            }
    }

    /**
     * @dev Hook that is called before a set of serially-ordered token IDs
     * are about to be transferred. This includes minting.
     * And also called before burning one token.
     *
     * `startTokenId` - the first token ID to be transferred.
     * `quantity` - the amount to be transferred.
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
     * @dev Hook that is called after a set of serially-ordered token IDs
     * have been transferred. This includes minting.
     * And also called after one token has been burned.
     *
     * `startTokenId` - the first token ID to be transferred.
     * `quantity` - the amount to be transferred.
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
     * @dev Private function to invoke {IERC721Receiver-onERC721Received} on a target contract.
     *
     * `from` - Previous owner of the given token ID.
     * `to` - Target address that will receive the token.
     * `tokenId` - Token ID to be transferred.
     * `_data` - Optional data to send along with the call.
     *
     * Returns whether the call correctly returned the expected magic value.
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

    // =============================================================
    //                        MINT OPERATIONS
    // =============================================================

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
    function _mint(address to, uint256 quantity) internal virtual {
        uint256 startTokenId = _currentIndex;
        if (quantity == 0) revert MintZeroQuantity();

        _beforeTokenTransfers(address(0), to, startTokenId, quantity);

        // Overflows are incredibly unrealistic.
        // `balance` and `numberMinted` have a maximum limit of 2**64.
        // `tokenId` has a maximum limit of 2**256.
        unchecked {
            // Updates:
            // - `balance += quantity`.
            // - `numberMinted += quantity`.
            //
            // We can directly add to the `balance` and `numberMinted`.
            _packedAddressData[to] += quantity * ((1 << _BITPOS_NUMBER_MINTED) | 1);

            // Updates:
            // - `address` to the owner.
            // - `startTimestamp` to the timestamp of minting.
            // - `burned` to `false`.
            // - `nextInitialized` to `quantity == 1`.
            _packedOwnerships[startTokenId] = _packOwnershipData(
                to,
                _nextInitializedFlag(quantity) | _nextExtraData(address(0), to, 0)
            );

            uint256 toMasked;
            uint256 end = startTokenId + quantity;

            // Use assembly to loop and emit the `Transfer` event for gas savings.
            // The duplicated `log4` removes an extra check and reduces stack juggling.
            // The assembly, together with the surrounding Solidity code, have been
            // delicately arranged to nudge the compiler into producing optimized opcodes.
            assembly {
                // Mask `to` to the lower 160 bits, in case the upper bits somehow aren't clean.
                toMasked := and(to, _BITMASK_ADDRESS)
                // Emit the `Transfer` event.
                log4(
                    0, // Start of data (0, since no data).
                    0, // End of data (0, since no data).
                    _TRANSFER_EVENT_SIGNATURE, // Signature.
                    0, // `address(0)`.
                    toMasked, // `to`.
                    startTokenId // `tokenId`.
                )

                // The `iszero(eq(,))` check ensures that large values of `quantity`
                // that overflows uint256 will make the loop run out of gas.
                // The compiler will optimize the `iszero` away for performance.
                for {
                    let tokenId := add(startTokenId, 1)
                } iszero(eq(tokenId, end)) {
                    tokenId := add(tokenId, 1)
                } {
                    // Emit the `Transfer` event. Similar to above.
                    log4(0, 0, _TRANSFER_EVENT_SIGNATURE, 0, toMasked, tokenId)
                }
            }
            if (toMasked == 0) revert MintToZeroAddress();

            _currentIndex = end;
        }
        _afterTokenTransfers(address(0), to, startTokenId, quantity);
    }

    /**
     * @dev Mints `quantity` tokens and transfers them to `to`.
     *
     * This function is intended for efficient minting only during contract creation.
     *
     * It emits only one {ConsecutiveTransfer} as defined in
     * [ERC2309](https://eips.ethereum.org/EIPS/eip-2309),
     * instead of a sequence of {Transfer} event(s).
     *
     * Calling this function outside of contract creation WILL make your contract
     * non-compliant with the ERC721 standard.
     * For full ERC721 compliance, substituting ERC721 {Transfer} event(s) with the ERC2309
     * {ConsecutiveTransfer} event is only permissible during contract creation.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - `quantity` must be greater than 0.
     *
     * Emits a {ConsecutiveTransfer} event.
     */
    function _mintERC2309(address to, uint256 quantity) internal virtual {
        uint256 startTokenId = _currentIndex;
        if (to == address(0)) revert MintToZeroAddress();
        if (quantity == 0) revert MintZeroQuantity();
        if (quantity > _MAX_MINT_ERC2309_QUANTITY_LIMIT) revert MintERC2309QuantityExceedsLimit();

        _beforeTokenTransfers(address(0), to, startTokenId, quantity);

        // Overflows are unrealistic due to the above check for `quantity` to be below the limit.
        unchecked {
            // Updates:
            // - `balance += quantity`.
            // - `numberMinted += quantity`.
            //
            // We can directly add to the `balance` and `numberMinted`.
            _packedAddressData[to] += quantity * ((1 << _BITPOS_NUMBER_MINTED) | 1);

            // Updates:
            // - `address` to the owner.
            // - `startTimestamp` to the timestamp of minting.
            // - `burned` to `false`.
            // - `nextInitialized` to `quantity == 1`.
            _packedOwnerships[startTokenId] = _packOwnershipData(
                to,
                _nextInitializedFlag(quantity) | _nextExtraData(address(0), to, 0)
            );

            emit ConsecutiveTransfer(startTokenId, startTokenId + quantity - 1, address(0), to);

            _currentIndex = startTokenId + quantity;
        }
        _afterTokenTransfers(address(0), to, startTokenId, quantity);
    }

    /**
     * @dev Safely mints `quantity` tokens and transfers them to `to`.
     *
     * Requirements:
     *
     * - If `to` refers to a smart contract, it must implement
     * {IERC721Receiver-onERC721Received}, which is called for each safe transfer.
     * - `quantity` must be greater than 0.
     *
     * See {_mint}.
     *
     * Emits a {Transfer} event for each mint.
     */
    function _safeMint(
        address to,
        uint256 quantity,
        bytes memory _data
    ) internal virtual {
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
     * @dev Equivalent to `_safeMint(to, quantity, '')`.
     */
    function _safeMint(address to, uint256 quantity) internal virtual {
        _safeMint(to, quantity, '');
    }

    // =============================================================
    //                        BURN OPERATIONS
    // =============================================================

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

        (uint256 approvedAddressSlot, address approvedAddress) = _getApprovedSlotAndAddress(tokenId);

        if (approvalCheck) {
            // The nested ifs save around 20+ gas over a compound boolean condition.
            if (!_isSenderApprovedOrOwner(approvedAddress, from, _msgSenderERC721A()))
                if (!isApprovedForAll(from, _msgSenderERC721A())) revert TransferCallerNotOwnerNorApproved();
        }

        _beforeTokenTransfers(from, address(0), tokenId, 1);

        // Clear approvals from the previous owner.
        assembly {
            if approvedAddress {
                // This is equivalent to `delete _tokenApprovals[tokenId]`.
                sstore(approvedAddressSlot, 0)
            }
        }

        // Underflow of the sender's balance is impossible because we check for
        // ownership above and the recipient's balance can't realistically overflow.
        // Counter overflow is incredibly unrealistic as `tokenId` would have to be 2**256.
        unchecked {
            // Updates:
            // - `balance -= 1`.
            // - `numberBurned += 1`.
            //
            // We can directly decrement the balance, and increment the number burned.
            // This is equivalent to `packed -= 1; packed += 1 << _BITPOS_NUMBER_BURNED;`.
            _packedAddressData[from] += (1 << _BITPOS_NUMBER_BURNED) - 1;

            // Updates:
            // - `address` to the last owner.
            // - `startTimestamp` to the timestamp of burning.
            // - `burned` to `true`.
            // - `nextInitialized` to `true`.
            _packedOwnerships[tokenId] = _packOwnershipData(
                from,
                (_BITMASK_BURNED | _BITMASK_NEXT_INITIALIZED) | _nextExtraData(from, address(0), prevOwnershipPacked)
            );

            // If the next slot may not have been initialized (i.e. `nextInitialized == false`) .
            if (prevOwnershipPacked & _BITMASK_NEXT_INITIALIZED == 0) {
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

    // =============================================================
    //                     EXTRA DATA OPERATIONS
    // =============================================================

    /**
     * @dev Directly sets the extra data for the ownership data `index`.
     */
    function _setExtraDataAt(uint256 index, uint24 extraData) internal virtual {
        uint256 packed = _packedOwnerships[index];
        if (packed == 0) revert OwnershipNotInitializedForExtraData();
        uint256 extraDataCasted;
        // Cast `extraData` with assembly to avoid redundant masking.
        assembly {
            extraDataCasted := extraData
        }
        packed = (packed & _BITMASK_EXTRA_DATA_COMPLEMENT) | (extraDataCasted << _BITPOS_EXTRA_DATA);
        _packedOwnerships[index] = packed;
    }

    /**
     * @dev Called during each token transfer to set the 24bit `extraData` field.
     * Intended to be overridden by the cosumer contract.
     *
     * `previousExtraData` - the value of `extraData` before transfer.
     *
     * Calling conditions:
     *
     * - When `from` and `to` are both non-zero, `from`'s `tokenId` will be
     * transferred to `to`.
     * - When `from` is zero, `tokenId` will be minted for `to`.
     * - When `to` is zero, `tokenId` will be burned by `from`.
     * - `from` and `to` are never both zero.
     */
    function _extraData(
        address from,
        address to,
        uint24 previousExtraData
    ) internal view virtual returns (uint24) {}

    /**
     * @dev Returns the next extra data for the packed ownership data.
     * The returned result is shifted into position.
     */
    function _nextExtraData(
        address from,
        address to,
        uint256 prevOwnershipPacked
    ) private view returns (uint256) {
        uint24 extraData = uint24(prevOwnershipPacked >> _BITPOS_EXTRA_DATA);
        return uint256(_extraData(from, to, extraData)) << _BITPOS_EXTRA_DATA;
    }

    // =============================================================
    //                       OTHER OPERATIONS
    // =============================================================

    /**
     * @dev Returns the message sender (defaults to `msg.sender`).
     *
     * If you are writing GSN compatible contracts, you need to override this function.
     */
    function _msgSenderERC721A() internal view virtual returns (address) {
        return msg.sender;
    }

    /**
     * @dev Converts a uint256 to its ASCII string decimal representation.
     */
    function _toString(uint256 value) internal pure virtual returns (string memory str) {
        assembly {
            // The maximum value of a uint256 contains 78 digits (1 byte per digit), but
            // we allocate 0xa0 bytes to keep the free memory pointer 32-byte word aligned.
            // We will need 1 word for the trailing zeros padding, 1 word for the length,
            // and 3 words for a maximum of 78 digits. Total: 5 * 0x20 = 0xa0.
            let m := add(mload(0x40), 0xa0)
            // Update the free memory pointer to allocate.
            mstore(0x40, m)
            // Assign the `str` to the end.
            str := sub(m, 0x20)
            // Zeroize the slot after the string.
            mstore(str, 0)

            // Cache the end of the memory to calculate the length later.
            let end := str

            // We write the string from rightmost digit to leftmost digit.
            // The following is essentially a do-while loop that also handles the zero case.
            // prettier-ignore
            for { let temp := value } 1 {} {
                str := sub(str, 1)
                // Write the character to the pointer.
                // The ASCII index of the '0' character is 48.
                mstore8(str, add(48, mod(temp, 10)))
                // Keep dividing `temp` until zero.
                temp := div(temp, 10)
                // prettier-ignore
                if iszero(temp) { break }
            }

            let length := sub(end, str)
            // Move the pointer 32 bytes leftwards to make room for the length.
            str := sub(str, 0x20)
            // Store the length.
            mstore(str, length)
        }
    }
}

// SPDX-License-Identifier: MIT
// ERC721A Contracts v4.2.3
// Creator: Chiru Labs

pragma solidity ^0.8.4;

/**
 * @dev Interface of ERC721A.
 */
interface IERC721A {
    /**
     * The caller must own the token or be an approved operator.
     */
    error ApprovalCallerNotOwnerNorApproved();

    /**
     * The token does not exist.
     */
    error ApprovalQueryForNonexistentToken();

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
     * Cannot safely transfer to a contract that does not implement the
     * ERC721Receiver interface.
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

    /**
     * The `quantity` minted with ERC2309 exceeds the safety limit.
     */
    error MintERC2309QuantityExceedsLimit();

    /**
     * The `extraData` cannot be set on an unintialized ownership slot.
     */
    error OwnershipNotInitializedForExtraData();

    // =============================================================
    //                            STRUCTS
    // =============================================================

    struct TokenOwnership {
        // The address of the owner.
        address addr;
        // Stores the start time of ownership with minimal overhead for tokenomics.
        uint64 startTimestamp;
        // Whether the token has been burned.
        bool burned;
        // Arbitrary data similar to `startTimestamp` that can be set via {_extraData}.
        uint24 extraData;
    }

    // =============================================================
    //                         TOKEN COUNTERS
    // =============================================================

    /**
     * @dev Returns the total number of tokens in existence.
     * Burned tokens will reduce the count.
     * To get the total number of tokens minted, please see {_totalMinted}.
     */
    function totalSupply() external view returns (uint256);

    // =============================================================
    //                            IERC165
    // =============================================================

    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * [EIP section](https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified)
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);

    // =============================================================
    //                            IERC721
    // =============================================================

    /**
     * @dev Emitted when `tokenId` token is transferred from `from` to `to`.
     */
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables `approved` to manage the `tokenId` token.
     */
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables or disables
     * (`approved`) `operator` to manage all of its assets.
     */
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    /**
     * @dev Returns the number of tokens in `owner`'s account.
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
     * @dev Safely transfers `tokenId` token from `from` to `to`,
     * checking first that contract recipients are aware of the ERC721 protocol
     * to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be have been allowed to move
     * this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement
     * {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external payable;

    /**
     * @dev Equivalent to `safeTransferFrom(from, to, tokenId, '')`.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external payable;

    /**
     * @dev Transfers `tokenId` from `from` to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {safeTransferFrom}
     * whenever possible.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token
     * by either {approve} or {setApprovalForAll}.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external payable;

    /**
     * @dev Gives permission to `to` to transfer `tokenId` token to another account.
     * The approval is cleared when the token is transferred.
     *
     * Only a single account can be approved at a time, so approving the
     * zero address clears previous approvals.
     *
     * Requirements:
     *
     * - The caller must own the token or be an approved operator.
     * - `tokenId` must exist.
     *
     * Emits an {Approval} event.
     */
    function approve(address to, uint256 tokenId) external payable;

    /**
     * @dev Approve or remove `operator` as an operator for the caller.
     * Operators can call {transferFrom} or {safeTransferFrom}
     * for any token owned by the caller.
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
     * See {setApprovalForAll}.
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);

    // =============================================================
    //                        IERC721Metadata
    // =============================================================

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

    // =============================================================
    //                           IERC2309
    // =============================================================

    /**
     * @dev Emitted when tokens in `fromTokenId` to `toTokenId`
     * (inclusive) is transferred from `from` to `to`, as defined in the
     * [ERC2309](https://eips.ethereum.org/EIPS/eip-2309) standard.
     *
     * See {_mintERC2309} for more details.
     */
    event ConsecutiveTransfer(uint256 indexed fromTokenId, uint256 toTokenId, address indexed from, address indexed to);
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