// SPDX-License-Identifier: MIT
/* solhint-disable quotes */
pragma solidity ^0.8.7;

import "@openzeppelin/contracts/access/Ownable.sol";
import "./Interfaces.sol";
import "./AnonymiceLibrary.sol";
import "./RedactedLibrary.sol";

contract DNAChipDescriptor is Ownable {
    struct TraitData {
        string svgImageTag;
        string name;
    }

    address public dnaChipAddress;
    FreakChip public freakChip;
    RobotChip public robotChip;
    UnderworldChip public underworldChip;
    AlienChip public alienChip;
    mapping(uint256 => string) public basesToNames;
    // character => traitType => traits
    mapping(uint8 => mapping(uint8 => TraitData[])) private _traitDataByCharacter;

    constructor() {
        freakChip = new FreakChip();
        robotChip = new RobotChip();
        underworldChip = new UnderworldChip();
        alienChip = new AlienChip();
        basesToNames[1] = "Freak";
        basesToNames[2] = "Robot";
        basesToNames[3] = "Underworld";
        basesToNames[4] = "Alien";
    }

    function setAddresses(address _dnaChipAddress) external onlyOwner {
        dnaChipAddress = _dnaChipAddress;
    }

    function setTraitTypeData(
        uint8 base,
        uint8 traitType,
        TraitData[] calldata traits
    ) external onlyOwner {
        for (uint256 index = 0; index < traits.length; index++) {
            _traitDataByCharacter[base][traitType][index] = traits[index];
        }
    }

    function setTraitData(
        uint8 base,
        uint8 traitType,
        uint8 traitIndex,
        string calldata name,
        string calldata svgImageTag
    ) external onlyOwner {
        _traitDataByCharacter[base][traitType][traitIndex] = TraitData({svgImageTag: svgImageTag, name: name});
    }

    function tokenURI(uint256 _tokenId) public view returns (string memory) {
        uint256 traitsRepresentation = IDNAChip(dnaChipAddress).tokenIdToTraits(_tokenId);
        string memory name;
        if (traitsRepresentation == 0) {
            uint8 base = IDNAChip(dnaChipAddress).tokenIdToBase(_tokenId);
            uint8 level = IDNAChip(dnaChipAddress).tokenIdToLevel(_tokenId);
            name = string(abi.encodePacked('{"name": "DNA Chip #', AnonymiceLibrary.toString(_tokenId)));

            return
                string(
                    abi.encodePacked(
                        "data:application/json;base64,",
                        AnonymiceLibrary.encode(
                            bytes(
                                string(
                                    abi.encodePacked(
                                        name,
                                        '", "image": "data:image/svg+xml;base64,',
                                        AnonymiceLibrary.encode(bytes(getBaseSVG(base, level))),
                                        '","attributes":',
                                        getMetadata(base, level),
                                        ', "description": "DNA Chips is a collection of 3,550 DNA Chips. All the metadata and images are generated and stored 100% on-chain. No IPFS, no API. Just the Ethereum blockchain."',
                                        "}"
                                    )
                                )
                            )
                        )
                    )
                );
        }

        uint8[8] memory traits = RedactedLibrary.representationToTraitsArray(traitsRepresentation);
        name = string(abi.encodePacked('{"name": "Evolution Pod #', AnonymiceLibrary.toString(_tokenId)));
        return
            string(
                abi.encodePacked(
                    "data:application/json;base64,",
                    AnonymiceLibrary.encode(
                        bytes(
                            string(
                                abi.encodePacked(
                                    name,
                                    '", "image": "data:image/svg+xml;base64,',
                                    AnonymiceLibrary.encode(bytes(getEvolutionPodSVG(traits[0]))),
                                    '","attributes":',
                                    getEvolutionPodMetadata(traits[0]),
                                    ', "description": "DNA Chips is a collection of 3,550 DNA Chips. All the metadata and images are generated and stored 100% on-chain. No IPFS, no API. Just the Ethereum blockchain."',
                                    "}"
                                )
                            )
                        )
                    )
                )
            );
    }

    function getBaseSVG(uint256 base, uint256 level) internal view returns (string memory) {
        if (base == 1) {
            return freakChip.getSvg(level);
        }
        if (base == 2) {
            return robotChip.getSvg(level);
        }
        if (base == 3) {
            return underworldChip.getSvg(level);
        }
        if (base == 4) {
            return alienChip.getSvg(level);
        }
        revert("invalid base");
    }

    function getEvolutionPodSVG(uint256 base) internal view returns (string memory) {
        if (base == 1) {
            return freakChip.getEvolutionPodSvg();
        }
        if (base == 2) {
            return robotChip.getEvolutionPodSvg();
        }
        if (base == 3) {
            return underworldChip.getEvolutionPodSvg();
        }
        if (base == 4) {
            return alienChip.getEvolutionPodSvg();
        }
        revert("invalid base");
    }

    function getEvolutionPreviewSVG(uint8[] memory traits) public view returns (string memory) {
        uint8 base = traits[0];

        string
            memory result = '<svg id="ebaby" width="100%" height="100%" version="1.1" viewBox="0 0 24 24" xmlns="http://www.w3.org/2000/svg" xmlns:xlink="http://www.w3.org/1999/xlink">';
        for (uint8 index = 0; index < traits.length; index++) {
            uint8 traitValue = traits[index];
            result = string(abi.encodePacked(result, _traitDataByCharacter[base][index][traitValue].svgImageTag));
        }
        result = string(
            abi.encodePacked(
                result,
                "<style>#ebaby { shape-rendering: crispedges; image-rendering: -webkit-crisp-edges; image-rendering: -moz-crisp-edges; image-rendering: crisp-edges; image-rendering: pixelated; -ms-interpolation-mode: nearest-neighbor;</style></svg>"
            )
        );

        return result;
    }

    function getMetadata(uint256 base, uint256 level) internal view returns (string memory) {
        string memory metadataString;
        metadataString = string(
            abi.encodePacked(metadataString, '{"trait_type": "Type","value":"', basesToNames[base], '"}', ",")
        );
        metadataString = string(
            abi.encodePacked(metadataString, '{"trait_type": "Level","value":"', AnonymiceLibrary.toString(level), '"}')
        );

        return string(abi.encodePacked("[", metadataString, "]"));
    }

    function getEvolutionPodMetadata(uint256 base) internal view returns (string memory) {
        string memory metadataString;
        metadataString = string(
            abi.encodePacked(metadataString, '{"trait_type": "Type","value":"', basesToNames[base], '"}')
        );

        return string(abi.encodePacked("[", metadataString, "]"));
    }
}

contract FreakChip {
    function getEvolutionPodSvg() public pure returns (string memory) {
        return
            '<svg id="evolution-pod" width="100%" height="100%" version="1.1" viewBox="0 0 125 125" xmlns="http://www.w3.org/2000/svg" xmlns:xlink="http://www.w3.org/1999/xlink"><image x="0" y="0" width="125" height="125" image-rendering="pixelated" preserveAspectRatio="xMidYMid" xlink:href="data:image/png;base64,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" /> </svg>';
    }

    function getSvg(uint256 level) public pure returns (string memory) {
        if (level == 1)
            return
                '<svg id="dna-chip" width="100%" height="100%" version="1.1" viewBox="0 0 120 120" xmlns="http://www.w3.org/2000/svg" xmlns:xlink="http://www.w3.org/1999/xlink"> <text x="41" y="20" fill="red">Level 1</text> <image x="10" y="20" width="100" height="100" image-rendering="pixelated" preserveAspectRatio="xMidYMid" xlink:href="data:image/png;base64,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" /> </svg>';
        if (level == 2)
            return
                '<svg id="dna-chip" width="100%" height="100%" version="1.1" viewBox="0 0 120 120" xmlns="http://www.w3.org/2000/svg" xmlns:xlink="http://www.w3.org/1999/xlink"> <text x="41" y="20" fill="red">Level 2</text> <image x="10" y="20" width="100" height="100" image-rendering="pixelated" preserveAspectRatio="xMidYMid" xlink:href="data:image/png;base64,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" /> </svg>';
        if (level == 3)
            return
                '<svg id="dna-chip" width="100%" height="100%" version="1.1" viewBox="0 0 120 120" xmlns="http://www.w3.org/2000/svg" xmlns:xlink="http://www.w3.org/1999/xlink"> <text x="41" y="20" fill="red">Level 3</text> <image x="10" y="20" width="100" height="100" image-rendering="pixelated" preserveAspectRatio="xMidYMid" xlink:href="data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAAGQAAABkCAYAAABw4pVUAAAAAXNSR0IArs4c6QAACy1JREFUeJztnGtsHNUZhp/Zm732sA6JL5vEiUEh2DRcnDhJARUakSqgmuAUCblpUaomVUlVxL+iFrVCiFKK+NUU2oAgKKEt5AcNLpgWoVhpEIUGGwwtEMdE1LHjOPbasddr73pv0x/rWe9lxt7L7MzY2UeKsjszO+fb7/3ec+bMzjEUKVKkSJEiRYoUKbLkEfRqaPcfpZw/W7V/P0DuJ5hDGDl4MOcPv/KTwqfLVvAWcmBWgFQ0yUbqufMRqBCYUpBZtHDEQujWQ2SKaQRRcIUuyUps1wxuMY0gs+jhCjVM4RbDBUlxhqFJkWMx0imGCzKLkc5IxdCiMEyQVGccEJ4zKpQ0HpotDyOcYrRD4s54SHrAyDiUMMQphggiu+OA8JwpBlJQLoiq/ft1d4mRDpFM6IpUdC8Y3QUxoztSSSwUvV1ilEMWgztkdC0cXQUxuzvUikRPlxjhkMXkDhndCki3hlJFMNO8IxW1gtEjZr0dYuZ5x0LoUrx6C2KqGbkaRhaL7g5ZhM6Q0cUhujSiJMJidUqh49bTIUl3dBepUwpewHoKkvRlzOYQsxRI0SHZsXQdksjEaS+Hr3tFx1DUMbpQDHNIIhUNLsMTkSGXh0Nkik4xiUNkFoFTlrZDzHalZQb0vrlopqdLskWX2z6638uCxecMPbtRQ+72mnycUGNp3u2VXyw2l+iFrutDNFznoTfCyMGDS3Z9yKL4TURG7+5V9xVUi9Al8VVXS9UhsMhcAvrFasgaw0XkkqQ1iUvZIaZ9Ngsur9/Ugdhj/rOP/JvZJXmt2M0Vo5cjmHwseS6v5dy5YJggcvWZ0SmBfZPC5JY/G9K20Q4BoL9tQAiOBxn75BJOt5OKeheuehcA3h4vEz1eACrqXRzb1a5LTLsvZ0HWtNRKgLBOwSkVDS7WJLwv1ID7r70fCLceulkChMC+SSYL0srCmEIQ5i6/Va+8ch1r5hNw+L0RvnzxLP1/G2DDw1+Lt3+N7Swf59Ra/hj2t05U/nxGIob/JYfUq6wlPQ+ZRS3pAvMkq79tgP62Aa761MJtV6+lvqGB4dIy3v3qHD2nTzN9rY81LbWsaanNNwbdMVqQnL50YrLPAmcZB8ZxYqOR63WJoVAYetlr0lsohkwIZYx2CJisQo3GDIKYziFGNm4GQYoOScBQQeS+2iRjiaFjh4wZHCJTdAomEcRgp5jCGTKmECSFy9opphJEZ6eYyhkyphIkhcvSKRajA1AipXIlkt0ipfxLRW1/0nszugPM7RCIJVBIeA3pzkkVRW1/4nlM6z6zCyKovFY7JpP9phUDTNplQVKXktoF5fvPtN0VmNwh4qCL4BUzQtQWIewM53Uum9+GJWzFMVnCiEbxFQLDBblxy69V90X6Ra6wuaQLTQN5txN2hlnZ5SYSjgrztfnph7/Mu6180FUQpUREwlGsNovinMNqs+CfCLCso1KT9v0EcFaUqs5v1MTSU6SCD3BPdj4ef62WfP9EIKNzjd/hySmGTAV1VpSmbYuEo4LVNjfU/mLzr3KKIVMKJogsRKoICyXf6/XicrkKFVbWbSaKlChOoYQpiCBPdj5OJBTBardKkLkDElGqVoD3K09mdZ5bPLcrbs8npkgoIljt1oKIorkgiWL4JwJYbBYhGo6mdVNqCVfj4/X/ziuujb1fT9vWe+kM66+8VvH4+QRzVpQWTBTNB/VQIIy91CbJXygajkpj1lEhTJjqSA0Wq4US0ZHxjcM3g6+zorKS213KlZ4pJ10nGfV4uNuxK75NTQyYK5gJYVyYiExQNVmT1O06K0qlUCCseUFrKsiWezdz7uw5VtWuStr+jvh3aUPgRuHgthfksUUIhANYBAsO6/zi3O3YxZue1zlJdl1VKqliZPSZkEfwOr1MbBqTOrreoXXi/vg+/0SAwYHBvGJSQlOFt9y7GUC6pvVq1lfGqu9oxZ9onbifMeuosDyyAiDukvm6jFTeDL6eV2zZiiE7XI4fYLv4LFM+iQ94kF7PGb48+hUf/rVT0xwWRBCxphz3tmo+WncqqaqyIdsxJlvUxoiB6DlqLWvTtm8Xn+W476fczDO87NnB0IlhfBenNBekYBPDj9adYtPZrfRyJu4WJbze2FKD1MvOXK6CMmXaMSXMXBFgeMsFqb4j+UlHl28ZKFwBT/kkej1n6GUHo52XChZbQQSp/sMy7A+vZ9LpwyE66OVMfF+qOPnOOTKZt8iiy+2VBculN5zHaO1Id2/quXo9sdh72cFMX5CgL5hXvAuhy62Tmb4gQolA2bKy+BdMRMlBN/MMH/Bg2nYlARITDulJVRJMqStVis0WsDM9Po00o8+zFwURpLurmzrWKzcYsAPwo4a3mPJJlIsCB/+XflwvOyChu5MFyiTZ86GUdJn9V70Tj+mF09/O6rxaUVCHlD/mACD0dPq+oyOtBEqmKR0p48pyCJRMK54jscuA5GQ6l5fiH8turHEuV75YKJ0p4+hIa+yNH5hdQ2VfZYXx2Gb7zyD4aFbNZY2mgoRmQthL7DQ2NXLp6BRTjwbpvedzNtCoeHzpTFnS+0qxKu0YzwK/XqglWI3ENpoth2iP7sXjU28jNBiZe/10rMiCD4eyajMbNBUkGo4y6Z1bndd7z+ds6JgTw77KSmgwwiM9Ffz+1ijH3f9g+9BdSedothyium03L+10ArEEiuWiJvH5pnwAeHwj/MD1BlM+iWbxEIfZmfE5ErvjyRHtVyJqeg3dcFs96363FnFjmQQw9WgQhxjrtuRBXSa4ZwqIfcGbxjcJoiRKidX7wzf8vLTTiVgu8tHHXZrEt2ljU1yUbdMvcqJsH82WQxz27kxyayQcEYLlM4SmQggTFilxUA/6ggz1DBP2h7FaLULXMW1XI2rqkJtONiS9L3/MoTh+yNxJM910UxmolhLHEI9vhJd2VsXFWLsntlpqG9s5wXEuMsSrxGbu32VuBt7K9/kO98W31eCOfw7gyJHDcVGuPv49TuyE6rbdfOOJjXS2z4lutVml6IqIEPqWX3IcKU+KefSrURxOuxANRYmEo9mmaEE0c0ir1CK/lCCW7If4Mc20MPiAB8EOdVvr4scf2/MXAFZ31bF96C4CJdNpY4gsiLfWi7u6hqHhi7ira4hcH2KkYwwAd3VN/Pih4YtJ2xLfDw1fxDXgYtPGJu57dYRd975FY1Mjd9LM27Szot2d1Pbk6CTBPVM4jpTTd6oPaXbYsDvtgn9smvdfPqVB1tLRUpD4hXo7bTTTkiQKwNjPY93F8t/GxoQ7aeaprifSBNk2/SLlokB7dK9il/XFhv9y3WdZryVk08Ymvuk/QHt0LwBt9tcA4sLILjn/yXmmvf54rIGOkODrnibYE1Pl3effy7rtTNFMkPrOOgliXy6VdtoA4sLIVdnd1U3D2zfEPn/HtXh8I1SKVTRbDjHlkzhRtg8gaVD/7IZP2PCfm3KKURZDbkemzf4ajU2NBH4Tu6JqeeQe3qY9Hucs8VwdFdpyaj8TtBQEURTx+XyqU9rzTX3x1wd4nqe6ngDgui9uEErGnRlNhbtvOUXj+1vzDVf5vArFlMrQ4JDwz9X5/Vg2H5peZdV31qnumxEDlPiSn/hYI64V+n3ncPevxj2wOul4n8vL5AovJVUOlm9dlvQ5uUucORUSIiMS0dEoojf3e2JDtecZWnM+3oaSMN1d3QC4V7oXjyDzoSZWz+Y+xe2zx0vnm/popiWp25MFgXiiBLXzZBubmstFURR8Pt+8MWuBaZ9zre+sw7tynBVUEroQliDW5a3uqov/717pFgCGLgxplqT5XF5IIYoUKVKkSJEiS4z/A3NObEv6owJPAAAAAElFTkSuQmCC" /> </svg>';
        revert("invalid level");
    }
}

contract RobotChip {
    function getEvolutionPodSvg() public pure returns (string memory) {
        return
            '<svg id="evolution-pod" width="100%" height="100%" version="1.1" viewBox="0 0 125 125" xmlns="http://www.w3.org/2000/svg" xmlns:xlink="http://www.w3.org/1999/xlink"><image x="0" y="0" width="125" height="125" image-rendering="pixelated" preserveAspectRatio="xMidYMid" xlink:href="data:image/png;base64,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" /> </svg>';
    }

    function getSvg(uint256 level) public pure returns (string memory) {
        if (level == 1)
            return
                '<svg id="dna-chip" width="100%" height="100%" version="1.1" viewBox="0 0 120 120" xmlns="http://www.w3.org/2000/svg" xmlns:xlink="http://www.w3.org/1999/xlink"> <text x="41" y="20" fill="red">Level 1</text> <image x="10" y="20" width="100" height="100" image-rendering="pixelated" preserveAspectRatio="xMidYMid" xlink:href="data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAAGQAAABkCAYAAABw4pVUAAAAAXNSR0IArs4c6QAACiJJREFUeJztnG9sE+cdx7/n8584xiEpiJCDAGnEvwo00jaj6wpaB5sWVkSZMl7AJCaxVZo6waa9mTa1Q0VMvBnT0NgkWKWhaRljGS8QaSqRtAimrg2DTEOF0IDIn+IADYqxEzvns317Yd/lfL6zfbnn7rk4/khWzs/dPc/vnu/zfZ675/wEqFChQoUKFSpUqFCh7GGsLkDsHTB1/onb9wFAJBIMwBxc32Qug23rCIWijdvS3GdBVgA1xBqOOn+zApHGcYJkIeWIYljeQxiFuiBWO8JI+U5wC3VBFNjlCj0c4RZqgmg4g3qFSDHRdApth9B2hRZUG4btgqicQd0VWtB0Ci2HONEZaqg0FlsFUbiDAYBDP26zs/iS+d3vuwFk4rXbJTQcIrtDunAHY7tLbBNE6Q6nOgPIbyR2jyd2O0QE5oQzlNjqElsEmWtjhxZ2jSd2OmQujR1a2OIUywVRuwNwrkPU6I0nVmKXQ3KeO+aoQwAbXGKXIDkX4mSH0G4sFYcYw3KHWFqAXsU72SEShRqNlfHb4ZC8eas57BDA4kZshyB5F+B0h9BsMBWHGKd8HFJxRnFsdYgTLpgA5eMQNWNjw3g4NoKHD4fltPff+6sNIeXjlMZCZQyRaGhYiYaGlQC2yGltO75nQ0imKF+H6EF7rKHpFsufPLMXNxfeoZeC5S/XqMxlFYK2O4Dyfw4BDDjEKYOrDuU521sIJzgEoNcwbFkfQniNBy2Yg+ubymp9iCHxaTulrB0CEF8JZScMMPMzoHJyCFCkAdByhZNuJGxdYzgHXZK3JrHcHAKU2AhouMUJTrF9Fe4cconmit1ydAig0xDsdoUTHKGG2jp1Bzul4Fr2cnWIBPXxxGkuoS2IiBlRdN1iU6UxqnioQFsQRmdbhoQ7DAhKfc0jrbusoqdZEkw+Ba9/Pt1lFapwBgUqqv/GVfy3/yqi4SdofvY5vNT6dSxetBT37t/Cx9c+wCfXPsCmli3Y1LIFLc9v0cumlFiouMWpDnEE88IhB9c3OfmWFyDwL5zMQHNQpz6AOhGagjjWITQLrzjEYVARROqjHTaWUB07JGg/GAIVp+RAVRBli6ToFkc4Q8IJDlEy793iGEEojCuOcoaE5YLcPPxaXtrGwxeLnTZvneKyMvNTm9diFF4g0+JFAGLgpa9piiSharXSeerv6nS9/VrnapXjGCwVBAAeJFLicNVCDFctRNPfL2Pq48uldkfSuwnpPYXyuzpdb7/WuU65zdbEckGUXN6/y8jh6nclWt2YuvL18in63sUpWC5IldvNjEUmIX1G4S1aIYruRKsLMvtxbHcFWDyov/HJHZzavBbjjauZ8RVrxMUjnzEYHcSOXxcd1LF8mR+RiMAISRHxeMp0LH4/C4+bQU2Np+BxF4/tk7df+7n96x1teR/ys65TQLYf/8233wAAXAtGCp7H8zx8Pp/4774nxGL5ypcXged5xufz6R7z6Jc/kmNVCnLx2D5MJVNIpkXw6TQA4MDVm8Rik7D1OaS5uVkWQqpwvWN9Ph9CoRBWLidXfigUAsdxumVGB24y/tZXEL/2LwR37ZVjzYqEgJsVH08nMvG5XMzZVzch4Gax89J1YjFaJkhfXx8A4BoiaG5uxr1799Da2ipXhlThpTL8uX6rLsbK5by8XahMbt1G8dFf/oD6o38EsuMNz/NM3YGfYuLd34ruF77K1D4eQ3hwAHw6LS70egHCvQzxLksSQu2As2fPYuvWraSLIwZ78ggAIPXmWznpHMflfOd5npke+B+mb95A4tMb8Lpc4s5L14nVI1GH9PX1IR6Pw+/3i0YdoCQQCGim37qTNJzXc2u1L3FqakreZk8eyRNCSlNfA8dxou9LrfCu2cBEYpPA8F3DMRWCmCBKMQoJoVfZhVi+4sXs31mHh89H/qMbx7RGXFNvvqUplHRtHMeJT5c3MV/cuTX7oDQgJkg0GkUwGMwTIxAI4Ny5cwgGg+jq6sKePXtKzvP2wBgejAnYsWON6fh6PhzBsgYP1q9rKOn4QCCAkekEViiEUroqFAqB2/Ed8YveLtOxKSHS923fvh3t7e1YunRp3h1MV1cm4GAwiGg0CgCzEsUsWmKEw2FETryDmoNvo7a2Nu8c9X6lIBLsySMgOYYQEwSAuH//fgSDwbz9kiiAMTEkbg+MmYgug54zwuGwphhS5QuCAI9H+2EyGo3izJkz6OnpcY4g727ZiF5PHR67vKLH48HevXs1RTHCbMYZo2i1diNEo1F0dHRAEASighAZQ7YJE+LffPUAgM7OTrS3twPArIUxW1lWInW7nZ2dluRPQhDxJhvImdY+f/48/H4/2tpmfrlu1jW0kASQ6O7uRjwet6w8Ig5xM9qO7e7uhsvlgt/v13wodJpI6soHgCtXrgAA4vE40tk5LCsxLciSKi8+SxfvQqULU4rQ0tJS8BwrBNOqdIn+/v6SjrMSEg5hXnHx4nWx2vCJ/f39WLx4se7+xsZGM3FpMjo6qpk+Pj5OvKzZQKTL6hQXzPrVaCKRkLeXDA7K249Xr9atPDMkEom8cpyEaUF2XrouPYeUzMjICABgxYqZuRCpkmpDIYQ5DksGB3G3vt5seDnU1NRoluMkUYhNnbAsW5JLJDGk7Q0bNuRUUl3WFWGOA3f/Pj5UOMgsr3q9QHU1akMh8DyfI0pkluJnr5sYRATp6elBW1sbWJZlRFEEigjT889e1NXU4YVvPC+nSWJ86+5dvI/M9P2gIOCb+9/JHODdhoM/zDwxnzgtAIleOR1A/nd1WqIXQ2feRuuCBeB5Ht//6CP8+eWXZVGMIooiw7Ks4fOKQcwh3d2Zla67d++G1+vVdYuym1Ju6/Hp3WY01Kcw9mgIh4+lMPZIqoTm7N8hAEBD/arsviH53Ny0ZpB6/vd6vUwikcCFCxcI5TgDUbvVMnUAgGeWPIOq6iqEhkIiAHz3B+3yMf/4UyfqajLH7T7wel6/Xjc6ionGRoQ5DrFYjHiXVa3osnw+n+wO9Xilvu0VBIFR3oB0dHQQi0sJEUEkIVxuF9LJtOyMwKJMm5x6MjMVElgUgFfwAgAmIhP4ya8OAcgf1IH8SjKL1qAOZO60IpGZH10kk0lGEAQkk7kvxE6fPk00Hi1MC1LL1OUIIYkAQK74hCeRlyalK8XajJlp9hd/cchsaLosGxqStx+sWgVgRgSJ48ePW1Z+IUgIkiOEssJLQSmWEqVQr+/bxSxbuWy2Iebgn5rKfGIxxKurEQ8EEM/OLh89epRIGWYwLcjC6lpxQfUCw0IUgoELvGcaPqEKkfhTJikkERYniOXvZIj8lJSUGAxcYBQhPRHG4fZ65o0YAKHbXq1uxydUGc6H90zL25OxSbhZNxNPxUzFNtcwLYibdTOTscn8Zw7jc42YjE3m5JtMJfE0FjYT3pyDxBiSl8a6WKTSKcOTjayLZVLpmR9WzzcxKlSoUIz/A2tgCQW9SgjsAAAAAElFTkSuQmCC" /> </svg>';
        if (level == 2)
            return
                '<svg id="dna-chip" width="100%" height="100%" version="1.1" viewBox="0 0 120 120" xmlns="http://www.w3.org/2000/svg" xmlns:xlink="http://www.w3.org/1999/xlink"> <text x="41" y="20" fill="red">Level 2</text> <image x="10" y="20" width="100" height="100" image-rendering="pixelated" preserveAspectRatio="xMidYMid" xlink:href="data:image/png;base64,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" /> </svg>';
        if (level == 3)
            return
                '<svg id="dna-chip" width="100%" height="100%" version="1.1" viewBox="0 0 120 120" xmlns="http://www.w3.org/2000/svg" xmlns:xlink="http://www.w3.org/1999/xlink"> <text x="41" y="20" fill="red">Level 3</text> <image x="10" y="20" width="100" height="100" image-rendering="pixelated" preserveAspectRatio="xMidYMid" xlink:href="data:image/png;base64,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" /> </svg>';
        revert("invalid level");
    }
}

contract UnderworldChip {
    function getEvolutionPodSvg() public pure returns (string memory) {
        return
            '<svg id="evolution-pod" width="100%" height="100%" version="1.1" viewBox="0 0 125 125" xmlns="http://www.w3.org/2000/svg" xmlns:xlink="http://www.w3.org/1999/xlink"><image x="0" y="0" width="125" height="125" image-rendering="pixelated" preserveAspectRatio="xMidYMid" xlink:href="data:image/png;base64,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" /> </svg>';
    }

    function getSvg(uint256 level) public pure returns (string memory) {
        if (level == 1)
            return
                '<svg id="dna-chip" width="100%" height="100%" version="1.1" viewBox="0 0 120 120" xmlns="http://www.w3.org/2000/svg" xmlns:xlink="http://www.w3.org/1999/xlink"> <text x="41" y="20" fill="red">Level 1</text> <image x="10" y="20" width="100" height="100" image-rendering="pixelated" preserveAspectRatio="xMidYMid" xlink:href="data:image/png;base64,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" /> </svg>';
        if (level == 2)
            return
                '<svg id="dna-chip" width="100%" height="100%" version="1.1" viewBox="0 0 120 120" xmlns="http://www.w3.org/2000/svg" xmlns:xlink="http://www.w3.org/1999/xlink"> <text x="41" y="20" fill="red">Level 2</text> <image x="10" y="20" width="100" height="100" image-rendering="pixelated" preserveAspectRatio="xMidYMid" xlink:href="data:image/png;base64,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" /> </svg>';
        if (level == 3)
            return
                '<svg id="dna-chip" width="100%" height="100%" version="1.1" viewBox="0 0 120 120" xmlns="http://www.w3.org/2000/svg" xmlns:xlink="http://www.w3.org/1999/xlink"> <text x="41" y="20" fill="red">Level 3</text> <image x="10" y="20" width="100" height="100" image-rendering="pixelated" preserveAspectRatio="xMidYMid" xlink:href="data:image/png;base64,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" /> </svg>';
        revert("invalid level");
    }
}

contract AlienChip {
    function getEvolutionPodSvg() public pure returns (string memory) {
        return
            '<svg id="evolution-pod" width="100%" height="100%" version="1.1" viewBox="0 0 125 125" xmlns="http://www.w3.org/2000/svg" xmlns:xlink="http://www.w3.org/1999/xlink"><image x="0" y="0" width="125" height="125" image-rendering="pixelated" preserveAspectRatio="xMidYMid" xlink:href="data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAAH0AAAB9CAMAAAC4XpwXAAAAAXNSR0IArs4c6QAAAgRQTFRFAGHOAGvjAJP4CHz/CTI3CyotDX7/DZz5D2CXEkdNF4LLGH3AHFBsIH6/Nj9fOkRsOkh6P+T1UYr/V6X/WKX/XKj/Y6z/bbT/brH/c7X/d8P5fKf/gbz/grz/hL7/hsD/h7//jsP/lsj/l8n/mJiYmngAncr/n8v/oEkAoc3/os3/o87/pXwopc7+popMps/+qKioqtL/r9T+r9X/sNX+sbGxscz/stX/tNf+tra2t9j9t9j/uNj9udn9u7u7vI83vNr9vtv9v4gGv9z8wMDAwN38wd78woICxcXFxd78xt/8x+D8yeD7y+L7zeH7zuP8z+X80NDQ0OT80ub71K1U1ej71uf715gG1+j72un73Oj/3er63rx23uv63+z64LJa4O364e364p0Q4rVa4uLi4u3646Ys4+765OTk5bdZ57Za5+/56KUH6cR+6fH56vH56vL57PL57/P57/T58KqB8PT48b1a8fT48r5Z8vX59Pb59cBZ9ff59r079sBY9sFa9sJY98FZ+LCG+Pj4+Pj5+cJY+cRW+fn5+sNZ+sVX+tGF+8RY+8ZY/MRY/MZX/cRY/cdY/qkA/7YI/7cN/7kn/74m/8NU/8RW/8RX/8VQ/8VS/8VT/8VU/8VV/8ZT/8ZV/8ZW/8dU/8dV/8dW/8dX/9Ru/9eH/9eI/96g/+Ot/+7G//fxv3JUewAAC8hJREFUaN7tmP9/FEcZx49wafcWQ9K7qrXYb4KiUU4qbm0VtVwhpELB0INNQ1CDIawygLVq5cuV9i6AhAL1zKmBStWabbn+kz7PMzO7M7Oze3uX+OIXnyS3t7u3857P823mUlh5mFZYj0HCh0gPw7VqD8NBxwjXABf0cGGhWrWO0kTLZIdrmG9BwCP87BKYDk/HfzoIHFChQofzkydPCrxCb6pmSbRPwfrOP640jOh0HqmX9KZpuvMWHjx4YIF/NTTCYvpGwAQe6SfR5DVBb2bRwwWgLzxIwFXtwF0m0ycQ/hlMo/PpoO8Fvdls9pK+gOKzHAxc6dOFMEs7Ryue7wUXgz7Igi8oVg3T4x7NJ866LLbUnpXtOtzAV6tazmdUXFre0k96QQN8v2KID1PrXe02eegoPlV6GBLxW4rRBdsDBbNt5KKnFzayifhjxcQUknx9lSE0twG7PrJjojBxAfj/U3pI7NjbwsQU4GKYk65MYjbvbADONVKmxSamAPcMvEE3bKkvXyAc2QsWq1aJb+CztSsTyUvfv7JshVerK/s1ehjTRUsB+qz4sYWgR9IL7Wl0XTstSAXiyo6WP+v01UyL+7IdXjXiTtq1htpHzoepOb9sh1dtOa/18/Wp92Ur3FrvOr25Rjrvs8tJdtXaawvmcpaPnLHZw/3MsoGGRcS6A0zQm3nozV5b3WWVXE3ZLw9CT678lqmE1WoOeBp9dqkXtpm9Awkz4FGRY7exBN6mv9nsDx+GUcRTB0rQs3Ie7/+O/6LBG3HA36Y1/5K51tTpdGHFgBPdcZxHH83vgFwl2UzQ4xtatwG46xp4pdb6hIeWhxJrnFxlEO6imXh1Jup4lvufJBYGY74Ze5ve9F72SUK74aw1ae+LngzXSrZ2h+CD0920Hi1DlbWrRPxa4Fa6nENiZ+UKi+sdKq43Y2kAenJf5yTpvZ/PoG9C60lHal56mJ++iZ7e1INOUE4f6kW37ObOolmHhqxxnJXe9KE07U6GdsaY76+cJe1n+4n7bLyKFJws7U5a3NttRnR/L9lKv3Qxvka3aE/BI7vme57XeqoFZvdPytMmfahPOpBrPrARPNO6fv1nP7LmRk56/ClwtdOLji4H1d4MwluV1tzcnqdaivf71e6698GS2h3X8jzzazVSXXkbX8utQ4e2l+HNnJdIevfJ9MCr9LtgOl3O575mmG190N18dDiN4G7U6/HSh8Lukgmvk8/Lv3ib6BMTny+3Tp/e5903DLTTMYMugTFcp99TDWqM6yb6kdOLi61HHtmwAehHjuyYV2Z5Vzjz3r37FpsVvr1P9CGiD2l06Y5/kf2DLNJdLlfAymiP/GVjAQ4zM5WXdkaz/CsZaP/Qakin+aXRHUn/pzQsM+/NNy9cx5AvnpmePnzw4OHD0xs2biyg/1uteW+bmCW3j+Dxj7jd0w3p9CaF7iip8HcylkYvFGI6TfNvYB+jgfaPTSNPIp0maKEvSToVP9gdNIbt5cTp0+d+v4iwt+bmpl9/fXp67q0yz3yi84n+Rxg+/G/DuB8BT7PM0E5NHke4ebNLqf7aT49VxssY85nW4vnzp06cOHXq/KJKv3PHcT8gwwM+y8+UlCZfAh1n6RYca84r9CH3BtXZnj0TBw5Vxg/urlDGX74crJ4bx9TjHa91Gug4yPvv375923HpxYXDrVu3NDi6kre7D1ybdjemYzeg1cz7zosv/vCVn1TGj75KuCAI2hcvjldePYplB92+dUTQb6A5cPgT99vNm45OvxntHlW6a6PzpTQvHR++du3qVXj86lU8XKUDKHsyHv2GlW7VTmxI9m9++/nnv/v9PTMzp44iPVilvjNe2X3weBCQ51/7yryHD1+5cuU9ePw9NIcOBv1abu2sCwlX8zzeWrDFXDwD9KDN+854ZcuWLaurXmsGb7/k7qTHL1265NArHtx33jHo71rougk6OT3qreTy1vVyEKzijFpIn4L3EBe8VUw1omP0KQMuGXTXon2pX3pxNNWKMR0xs5FCC91R6dhjLly/rtBb4P42ln+lDNUftBmnF0fHUm20qHr+j7PRElYgx5OfxTwcTTsk3NHjZ85cJDrGfQbYbWo+pB3edrs1r3wO6Y89Br8JM+l/ILoj6UKxSeeV5u1+BaoruMDVT4Eh3ffm5i5A8vF6rHmVY0gfHR2z+B3pWsEbdBA/pNPBMN19b/v2bwSr7XY7WJR08nXNm5g4Ru+66J6pyoFsz7tunHUR3YnoCe1sADr3PP8b0zwPA38uQXez6AR59llMalY7/tuIDucQ6R079tEd2nFMVV6OPc//xjTPq3HP0i4rAAeGYQMUCOoqlRdegJwT0gH53HMczntRZXdPz2fF3dV3lY7bpYGD1VWe37zayoGETwUC7nuTk48//qWXuecVl4+l5fyvDe2urp1qkY8c0Kuo9cUzRO9CD5gip3QF/YknvnyAe15x+Via53+VUXGc7rNB6Pm6jdtTO6d7gUK/fPl7XytTgQO9ApvYLSLsk5PPPLN1Xng+8jl/oWD4Ov2X1pwfUabH6UyM/8Yb2F5hnatgGvAWTxnQaBB9cnJ+p/B85PMx4fTRUZ/p9J9naxf0TgerGRsZrK1l+Kr6A5lyJn0KNhbpnjfp5HmOK8QXufYlSe80GnUqtmiF4Wnue7t2/Yb2NkjHsE8CfFV6HpNe6/gwVJLuGPSliO4MTOceZ3rHz0V3zbgDHfCeNz13keiBWFNq3tatu4I2ZECnUa9Dl51HOIs9zwy/I93sNvx/Fhmeh7gDHbTvO3bhQqsi1zPmffHppykB4DbW3t75eYCzuNswJrNdON6qXa/3ETDR6KKc75DvvYm5udZMEO1uv0AR6GBkgL53fts2XO/jbgO00agAcKC406pbGNdGl9YfHfxYHN1Mhh/aLA3hm/nOKmbG+/s0epvTIbLM2431jgnXwEYzxedBcfF9gMMpDSe2kPig3E5yFxZds6wdC93VtXco7yD0sI8JcAvVYDGd7vl7Ec4YH03tUMz1fV9c8WM4p65YtSdzXtADsbR1odFMCXqnA9LnCe4ILQTrMIH0HRMu6XH0CyNWU+mw1ojVFJvslMh3lC4STp9zp8aRVDY1Fe4aX+jWmQ7EBtF9GgIyo6bCVTrHpNOjuPueLHWVXq/72zDhmL4+1IEo4Ax6kS8HNCsukz4yImqKmDKeuK7HdD4hc9Z1Lt2nL58RfMRweS/6iKx3JhsP5h/Ca3Raq1ngBJVwHoCI7khT6U5seB6fRQncVehBUBONoNFAkb58lB9E0VG6d5gvxuS27nTl0Zj+maA30ujKtWy6dHuHdz38Fy2LmyDTh4KHVe1131kDvSvBlPtRBnQEHudh0jlcil8TnUUujuE4E45H5as2usg3lkF3cnu+Xq/H9E5D9YJjalcava9nfN901jed4CNU5xSAPNrT/tfCxEqJEyCiiD/Bu7SG+voTvnR7p8P5xZ6WSe+Kd5jfdS0BGL/RNvHQAdBDsP6xIvMHpMvw0QlfXNEFEAYO7wo6S9BFOdZY0jc2esliUfLQWbtkocuPac/5Es5v+KVeVigV5Q83eGfQo+kQmU+Gicv4GkspRV8D0C2Mu75U0n6LMadYKqRJx+9RLOkOeVKyigd8PV6ZmN9bu53OJSTo7bbwsNRuAnzuIWx4LI/n7fQ4u+NrXXnmK9pZAh/v7Qak822N9B8Y64NeF3u7QenashJnQcLzJZn9uvQ60eHuQHFX4N2ohDuWrCsxU70v2jPgSznwado15eQMKV8tRxFjFc6nhLu7Um/n2+NeV+BiP9uQ8nHBpzfDw8NRTMxC5JsQyHy/T7qhMJ3O1xR+MiyrLDFAfvrwMNcjlEnjcMGk1aYu8qHbZSn2WS58QSOj+TY448LbfMXXkoI+Ek2a6Qrgr0FXMunDWRZt54YHsK/Hbweg+7CPFTtZf3htlsfzqfrXmWzPuvW2Put93Rn9dZv88yit0Qqlh2n/pz88Ou01oz1nybLrpo1rqSQ/WUz/MB+TDyf+StaxBPHhav8vDjjmVWC1DLcAAAAASUVORK5CYII="/> </svg>';
    }

    function getSvg(uint256 level) public pure returns (string memory) {
        if (level == 1)
            return
                '<svg id="dna-chip" width="100%" height="100%" version="1.1" viewBox="0 0 120 120" xmlns="http://www.w3.org/2000/svg" xmlns:xlink="http://www.w3.org/1999/xlink"> <text x="41" y="20" fill="red">Level 1</text> <image x="10" y="20" width="100" height="100" image-rendering="pixelated" preserveAspectRatio="xMidYMid" xlink:href="data:image/png;base64,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"/> </svg>';
        if (level == 2)
            return
                '<svg id="dna-chip" width="100%" height="100%" version="1.1" viewBox="0 0 120 120" xmlns="http://www.w3.org/2000/svg" xmlns:xlink="http://www.w3.org/1999/xlink"> <text x="41" y="20" fill="red">Level 2</text> <image x="10" y="20" width="100" height="100" image-rendering="pixelated" preserveAspectRatio="xMidYMid" xlink:href="data:image/png;base64,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" /> </svg>';
        if (level == 3)
            return
                '<svg id="dna-chip" width="100%" height="100%" version="1.1" viewBox="0 0 120 120" xmlns="http://www.w3.org/2000/svg" xmlns:xlink="http://www.w3.org/1999/xlink"> <text x="41" y="20" fill="red">Level 3</text> <image x="10" y="20" width="100" height="100" image-rendering="pixelated" preserveAspectRatio="xMidYMid" xlink:href="data:image/png;base64,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"/> </svg>';
        revert("invalid level");
    }
}

/* solhint-enable quotes */

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

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

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

interface RewardLike {
    function mintMany(address to, uint256 amount) external;
}

interface IDNAChip is RewardLike {
    function tokenIdToBase(uint256 tokenId) external view returns (uint8);

    function tokenIdToLevel(uint256 tokenId) external view returns (uint8);

    function tokenIdToTraits(uint256 tokenId) external view returns (uint256);
}

interface IDescriptor {
    function tokenURI(uint256 _tokenId) external view returns (string memory);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

library AnonymiceLibrary {
    string internal constant TABLE =
        "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";

    function encode(bytes memory data) internal pure returns (string memory) {
        if (data.length == 0) return "";

        // load the table into memory
        string memory table = TABLE;

        // multiply by 4/3 rounded up
        uint256 encodedLen = 4 * ((data.length + 2) / 3);

        // add some extra buffer at the end required for the writing
        string memory result = new string(encodedLen + 32);

        assembly {
            // set the actual output length
            mstore(result, encodedLen)

            // prepare the lookup table
            let tablePtr := add(table, 1)

            // input ptr
            let dataPtr := data
            let endPtr := add(dataPtr, mload(data))

            // result ptr, jump over length
            let resultPtr := add(result, 32)

            // run over the input, 3 bytes at a time
            for {

            } lt(dataPtr, endPtr) {

            } {
                dataPtr := add(dataPtr, 3)

                // read 3 bytes
                let input := mload(dataPtr)

                // write 4 characters
                mstore(
                    resultPtr,
                    shl(248, mload(add(tablePtr, and(shr(18, input), 0x3F))))
                )
                resultPtr := add(resultPtr, 1)
                mstore(
                    resultPtr,
                    shl(248, mload(add(tablePtr, and(shr(12, input), 0x3F))))
                )
                resultPtr := add(resultPtr, 1)
                mstore(
                    resultPtr,
                    shl(248, mload(add(tablePtr, and(shr(6, input), 0x3F))))
                )
                resultPtr := add(resultPtr, 1)
                mstore(
                    resultPtr,
                    shl(248, mload(add(tablePtr, and(input, 0x3F))))
                )
                resultPtr := add(resultPtr, 1)
            }

            // padding with '='
            switch mod(mload(data), 3)
            case 1 {
                mstore(sub(resultPtr, 2), shl(240, 0x3d3d))
            }
            case 2 {
                mstore(sub(resultPtr, 1), shl(248, 0x3d))
            }
        }

        return result;
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
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

    function parseInt(string memory _a)
        internal
        pure
        returns (uint8 _parsedInt)
    {
        bytes memory bresult = bytes(_a);
        uint8 mint = 0;
        for (uint8 i = 0; i < bresult.length; i++) {
            if (
                (uint8(uint8(bresult[i])) >= 48) &&
                (uint8(uint8(bresult[i])) <= 57)
            ) {
                mint *= 10;
                mint += uint8(bresult[i]) - 48;
            }
        }
        return mint;
    }

    function substring(
        string memory str,
        uint256 startIndex,
        uint256 endIndex
    ) internal pure returns (string memory) {
        bytes memory strBytes = bytes(str);
        bytes memory result = new bytes(endIndex - startIndex);
        for (uint256 i = startIndex; i < endIndex; i++) {
            result[i - startIndex] = strBytes[i];
        }
        return string(result);
    }

    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        assembly {
            size := extcodesize(account)
        }
        return size > 0;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

library RedactedLibrary {
    struct Traits {
        uint256 base;
        uint256 earrings;
        uint256 eyes;
        uint256 hats;
        uint256 mouths;
        uint256 necks;
        uint256 noses;
        uint256 whiskers;
    }

    struct TightTraits {
        uint8 base;
        uint8 earrings;
        uint8 eyes;
        uint8 hats;
        uint8 mouths;
        uint8 necks;
        uint8 noses;
        uint8 whiskers;
    }

    function traitsToRepresentation(Traits memory traits) internal pure returns (uint256) {
        uint256 representation = uint256(traits.base);
        representation |= traits.earrings << 8;
        representation |= traits.eyes << 16;
        representation |= traits.hats << 24;
        representation |= traits.mouths << 32;
        representation |= traits.necks << 40;
        representation |= traits.noses << 48;
        representation |= traits.whiskers << 56;

        return representation;
    }

    function representationToTraits(uint256 representation) internal pure returns (Traits memory traits) {
        traits.base = uint8(representation);
        traits.earrings = uint8(representation >> 8);
        traits.eyes = uint8(representation >> 16);
        traits.hats = uint8(representation >> 24);
        traits.mouths = uint8(representation >> 32);
        traits.necks = uint8(representation >> 40);
        traits.noses = uint8(representation >> 48);
        traits.whiskers = uint8(representation >> 56);
    }

    function representationToTraitsArray(uint256 representation) internal pure returns (uint8[8] memory traitsArray) {
        traitsArray[0] = uint8(representation); // base
        traitsArray[1] = uint8(representation >> 8); // earrings
        traitsArray[2] = uint8(representation >> 16); // eyes
        traitsArray[3] = uint8(representation >> 24); // hats
        traitsArray[4] = uint8(representation >> 32); // mouths
        traitsArray[5] = uint8(representation >> 40); // necks
        traitsArray[6] = uint8(representation >> 48); // noses
        traitsArray[7] = uint8(representation >> 56); // whiskers
    }
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