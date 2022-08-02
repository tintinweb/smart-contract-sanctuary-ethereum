// SPDX-License-Identifier: CC0-1.0
pragma solidity >=0.8.0 <0.9.0;
import "./Uint2str.sol";

interface IFace {
    function isWeird(uint256 tokenId) external pure returns (bool);
    function metadata(uint256 tokenId) external view returns (string memory);
    function element(uint256 tokenId) external view returns (string memory);
}

/** @title Youts - Face Metadata contract
  * @author @ok_0S / weatherlight.eth
  */
contract Face {
    using Uint2str for uint16;

    string[25] private humanFaceNames = [
        "Wiggle",
        "Blinker",
        "Grump",
        "I Liek U",
        "Grin",
        "U-On",
        "Stickout",
        "Black Eye",
        "uwu",
        "Browside Down",
        "Ring",
        "Rude Tude",
        "Devious Lick",
        "Uncle",
        "Nounish",
        "Tired Eye",
        "Smarty",
        "Mascara",
        "X'd Out",
        "2Cool",
        "Stoney",
        "Joyful",
        "Funhappy",
        "Straight Talker",
        "Bitey"
    ];

    string[14] private weirdFaceNames = [
        'North Tree', 
        'East Tree', 
        'West Tree', 
        'South Tree', 
        'Center Tree', 
        'U-shape', 
        'O-shape', 
        'Inverted U-shape', 
        'Rotated I-shape', 
        'Aligned', 
        'Four Eyes', 
        'Spiraling', 
        'Cyclops', 
        'Primal'
    ];
    

	/** @dev External wrapper function that returns true if a Yout is Weird
	  * @param tokenId A token's numeric ID. 
	  */
    function isWeird(uint256 tokenId) 
        external 
        pure 
        returns (bool) 
    {
        return
            _isWeird(tokenId);
    }	


    /** @dev Internal function that returns true if a Yout is Weird
	  * @param tokenId A token's numeric ID. 
	  */
    function _isWeird(uint256 tokenId) 
        internal 
        pure 
        returns (bool) 
    {
        return
            uint256(keccak256(abi.encodePacked("WEIRD", tokenId))) % 100 < 7 ? true : false;
    }
    

	/** @dev Renders a JSON string containing metadata for a Yout's face
	  * @param tokenId A token's numeric ID. 
	  */
    function metadata(uint256 tokenId) 
        external
        view 
        returns (string memory) 
    {
        string memory traits;

        bool weirdCheck = _isWeird(tokenId);

        traits = string(abi.encodePacked(
            '{"trait_type":"Origin","value":"', (weirdCheck ? _weirdOrigin(tokenId) : 'Human'), '"},',
            '{"trait_type":"Face","value":"', (weirdCheck ? _weirdFaceName(tokenId) : _humanFaceName(tokenId)),'"}'
        ));

        return
            traits;
    }


	/** @dev Renders a SVG element containing a Yout's face  
	  * @param tokenId A token's numeric ID. 
	  */
    function element(uint256 tokenId) 
        external 
        view 
        returns (string memory) 
    {
        return 
            string(abi.encodePacked(
                '<g id="f" filter="url(#ds)">', this.isWeird(tokenId) ? _weirdFace(tokenId) : _humanFace(tokenId), "</g>"
            ));
    }


    /** @dev Internal function that returns the weird origin associated with the given token ID.
      * @notice This function will return a weird origin for ANY token, even non-Weird Youts. 
	  * @param tokenId A token's numeric ID. 
	  */
    function _weirdOrigin(uint256 tokenId)
        internal
        view
        returns (string memory)
    {
        uint256 faceRoll = uint256(keccak256(abi.encodePacked("FACE", tokenId))) % weirdFaceNames.length;
        string memory faceOrigin;

        if (faceRoll < 5) {
            faceOrigin = "Spirit";
        } else if (faceRoll > 8) {
            faceOrigin = "Primordial";
        } else {
            faceOrigin = "Alien";
        }

        return
            faceOrigin;
    }


	/** @dev Internal function that returns the weird face name associated with the given token ID.
      * @notice This function will return a weird face name for ANY token, even non-Weird Youts. 
	  * @param tokenId A token's numeric ID. 
	  */
    function _weirdFaceName(uint256 tokenId)
        internal
        view
        returns (string memory)
    {
        return
            weirdFaceNames[uint256(keccak256(abi.encodePacked("FACE", tokenId))) % weirdFaceNames.length];
    }


	/** @dev Internal function that returns the name of the human face associated with the given token ID.
      * @notice This function will return a name even for ANY token, even non-Human Youts. 
	  * @param tokenId A token's numeric ID. 
	  */
    function _humanFaceName(uint256 tokenId)
        internal
        view
        returns (string memory)
    {
        return
            humanFaceNames[uint256(keccak256(abi.encodePacked("FACE", tokenId))) % humanFaceNames.length];
    }


	/** @dev Internal function that returns the human face associated with the given token ID.
      * @notice This function will return a face for ANY token, even non-Human Youts. 
	  * @param tokenId A token's numeric ID. 
	  */
    function _humanFace(uint256 tokenId) 
        internal 
        pure 
        returns (string memory) 
    {
        string[25] memory faces = [

            // WIGGLE
            string(abi.encodePacked(
                _eyes([400, 482, 637, 470]),
                _path(
                    'M350 542C358 576 403 582 428 565C453 548 472 541 500 562C529 584 551 578 576 557C601 536 642 545 659 565'
                )
            )),

            // BLINKER
            string(abi.encodePacked(
                _eyes([444, 505, 598, 468]),
                _path(
                    'M605 562C598 591 550 627 489 593'
                ),
                _path(
                    'M451 431C438 421 422 416 401 429'
                ),
                _path(
                    'M611 385C595 381 579 382 564 402'
                )
            )),

            // GRUMP
            string(abi.encodePacked(
                _eyes([630, 452, 439, 472]),
                _path(
                    'M457 578C477 538 584 496 637 571'
                ),
                _path(
                    'M556 455C570 427 644 398 680 450'
                ),
                _path(
                    'M373 478C384 449 455 414 496 462'
                )
            )),

            // I LIEK U
            string(abi.encodePacked(
                _eyes([388, 508, 639, 484]),
                _path(
                    'M580 572C580 587 568 607 536 608C493 609 485 591 484 581'
                )
            )),

            // GRIN
            string(abi.encodePacked(
                _eyes([589, 443, 382, 443]),
                _path(
                    'M398 553C422 595 529 629 573 542'
                ),
                _path(
                    'M449 440C433 410 352 382 314 440'
                ),
                _path(
                    'M649 440C633 410 552 382 514 440'
                )
            )),

            // U-ON
            string(abi.encodePacked(
                _eyes([567, 450, 461, 446]),
                _path(
                    'M555 532C555 554 559 603 514 603C469 603 473 554 473 532'
                )
            )),

            // STICKOUT
            string(abi.encodePacked(
                _eyes([365, 447, 633, 436]),
                _path(
                    'M614 498L402 505',
                    'r'
                ),
                _path(
                    'M585 506C585 529 589 577 544 577C499 577 503 529 503 506',
                    'r'
                )
            )),

            // BLACK EYE
            string(abi.encodePacked(
                _eyes([394, 487, 633, 458]),
                _path(
                    'M438 578C469 617 587 636 622 542'
                ),
                '<circle class="s0" cx="393" cy="486" r="46.5"/>'
            )),

            // UWU
            string(abi.encodePacked(
                _path(
                    'M662 433C667 464 613 502 580 447'
                ),
                _path(
                    'M326 459C327 491 387 518 410 458'
                ),
                _path(
                    'M426 546C452 605 499 571 497 538C499 571 551 598 567 535'
                )
            )),

            // BROWSIDE DOWN
            string(abi.encodePacked(
                _eyes([615, 567, 402, 578]),
                _path(
                    'M402 494C401 370 597 353 598 498'
                ),
                _path(
                    'M458 591C442 614 373 628 349 577'
                ),
                _path(
                    'M559 581C575 603 644 618 668 567'
                )
            )),

            // RING
            string(abi.encodePacked(
                _eyes([624, 462, 438, 458]),
                _path(
                    'M479 439C461 409 382 381 344 439'
                ),
                _path(
                    'M674 448C658 418 577 390 539 448'
                ),
                _path(
                    'M564 502C570 566 484 573 477 511'
                ),
                _path(
                    'M472 632C485 652 548 668 576 629'
                ),
                _path(
                    'M543 557C546 584 509 587 507 561', 
                    's1'
                )
            )),

            // RUDE TUDE
            string(abi.encodePacked(
                _line([600, 388, 400, 388]),
                _line([540, 443, 469, 443]),
                _path(
                    'M420 622C418 541 581 531 582 626'
                ),
                _path(
                    'M649 425C638 441 605 483 562 515'
                ),
                _path(
                    'M439 425C428 441 395 483 352 515'
                ),
                _path(
                    'M673 455C663 470 634 507 596 535', 
                    's3'
                ),
                _path(
                    'M463 455C453 470 424 507 386 535', 
                    's3'
                ),
                _path(
                    'M329 480C336 518 372 542 409 535C446 528 470 492 463 454C456 417 420 393 383 400C346 407 322 443 329 480Z'
                ),
                _path(
                    'M539 481C546 518 582 542 619 535C656 528 680 492 673 455C665 418 630 393 593 401C556 408 532 444 539 481Z'
                )
            )),

            // DEVIOUS LICK
            string(abi.encodePacked(
                _eyes([337, 462, 665, 438]),
                _path(
                    'M401 511C402 572 617 566 616 495'
                ),
                _path(
                    'M585 540C591 562 605 608 562 618C517 628 511 580 506 558'
                )
            )),

            // UNCLE
            string(abi.encodePacked(
                _eyes([622, 487, 396, 490]),
                _path(
                    'M647 455C633 445 617 441 597 455'
                ),
                _path(
                    'M421 455C407 445 391 441 371 455'
                ),
                _path(
                    'M602 574C593 572 551 567 531 568', 
                    's3 r'
                ),
                _path(
                    'M500 568C492 568 449 570 429 574', 
                    's3 r'
                )
            )),

            // NOUNISH
            string(abi.encodePacked(            
                _path(
                    'M358 449L262 449L262 510',
                    's3 mJ'
                ),
                _path(
                    'M431 598C447 600 524 599 566 599'
                ),
                _line(
                    [547, 449, 504, 449],
                    's3'
                ),
                '<rect x="554" y="403" width="125" height="125" class="s3"/>',
                '<rect x="365" y="403" width="125" height="125" class="s3"/>',
                '<rect x="629" y="429" width="25" height="75" class="fB s0"/>',
                '<rect x="440" y="429" width="25" height="75" class="fB s0"/>'
            )),

            // TIRED EYE
            string(abi.encodePacked(
                _eyes([364, 459, 649, 439]),
                _path(
                    'M449 582C492 628 584 616 598 553'
                ),
                _path(
                    'M316 491C333 516 403 520 416 471.102'
                )
            )),

            // SMARTY
            string(abi.encodePacked(
                _eyes([419, 480, 608, 481]),
                _path(
                    'M602 571C586 623 464 629 440 575'
                )
            )),

            // MASCARA
            string(abi.encodePacked(
                _eyes([603, 441, 417, 436]),
                _path(
                    'M681 429C667 419 651 415 631 429'
                ),
                _path(
                    'M389 426C375 416 359 412 339 426'
                ),
                _path(
                    'M501 442C528 452 557 510 509 541'
                ),
                _path(
                    'M451 611C464 630 527 647 555 607'
                )
            )),

            // X'D OUT
            string(abi.encodePacked(
                _line(
                    [372, 508, 410, 470],
                    'r'
                ),
                _line(
                    [372, 470, 410, 508],
                    'r'
                ),
                _line(
                    [597, 462, 635, 500],
                    'r'
                ),
                _line(
                    [597, 500, 635, 462],
                    'r'
                ),
                _eyes([616, 417, 391, 417]),
                _path(
                    'M539 558C535 576 516 586 499 582C481 577 471 559 475 541C480 523 498 513 516 517C534 522 544 540 539 558Z'
                )
            )),

            // 2COOL
            string(abi.encodePacked(
                _line([610, 423, 400, 423]),
                _line([545, 472, 465, 472]),
                _path(
                    'M475 629C495 616 540 629 558 618'
                ),
                _path(
                    'M652 460C641 476 608 518 565 550'
                ),
                _path(
                    'M442 460C431 476 398 518 355 550'
                ),
                _path(
                    'M676 490C666 505 637 542 599 570', 's3'
                ),
                _path(
                    'M466 490C456 505 427 542 389 570', 
                    's3'
                ),
                _path(
                    'M332 515C339 553 375 577 412 570C449 563 473 527 466 489C459 452 423 428 386 435C349 442 325 478 332 515Z'
                ),
                _path(
                    'M542 516C549 553 585 577 622 570C659 563 683 527 676 490C668 453 633 428 596 436C559 443 535 479 542 516Z'
                )
            )),

            // STONEY
            string(abi.encodePacked(
                _path(
                    'M360 435C369 419 414 404 435 435'
                ),
                _path(
                    'M558 435C567 419 612 404 633 435'
                ),
                _path(
                    'M526 489C529 536 465 538 463 493'
                ),
                _path(
                    'M389 541C383 658 593 682 601 546'
                ),
                _path(
                    'M521 523C523 558 476 560 473 527',
                    's1'
                )
            )),

            // JOYFUL
            string(abi.encodePacked(
                _path(
                    'M362 483C362 425 469 417 469 486'
                ),
                _path(
                    'M538 488C538 429 643 421 644 490'
                ),
                _path(
                    'M427 557C454 606 554 605 579 557'
                )
            )),

            // FUNHAPPY
            string(abi.encodePacked(
                _eyes([343, 461, 664, 461]),
                _path(
                    'M399 559C398 417 610 397 611 564'
                )
            )),

            // STRAIGHT TALKER
            string(abi.encodePacked(
                _line(
                    [370, 427, 424, 427],
                    'r'
                ),
                _line(
                    [567, 427, 623, 427],
                    'r'
                ),
                _eyes([397, 463, 596, 463]),
                _path(
                    'M443 552C458 561 532 569 566 552'
                )
            )),

            // BITEY
            string(abi.encodePacked(
                _eyes([419, 480, 610, 477]),
                _path(
                    'M655 430C645 424 600 427 583 446'
                ),
                _path(
                    'M374 436C384 429 429 428 447 446'
                ),
                _path(
                    'M622 536C615 549 605 565 588 576M415 552C430 569 437 572 449 581M588 576L589 616L564 588M588 576C580 580 572 584 564 588M564 588C537 598 506 602 477 593M477 593L453 621L449 581M477 593C467 590 458 586 449 581'
                )
            ))

        ];

        return
            faces[uint256(keccak256(abi.encodePacked("FACE", tokenId))) % faces.length];
    }


	/** @dev Internal function that returns the weird face associated with the given token ID.
      * @notice This function will return a face for ANY token, even non-Weird Youts.  
	  * @param tokenId A token's numeric ID. 
	  */
    function _weirdFace(uint256 tokenId) 
        internal 
        pure 
        returns (string memory) 
    {
        string[14] memory faces = [
            
            // SPIRIT / NORTH TREE
            string(abi.encodePacked(
                _eyes([311, 482, 585, 591]),
                '<circle class="s0" cx="497" cy="416" r="33.5"/>'
            )),

            // SPIRIT / EAST TREE
            string(abi.encodePacked(
                _eyes([381, 600, 438, 363]),
                '<circle class="s0" cx="578" cy="537" r="33.5"/>'
            )),

            // SPIRIT / WEST TREE
            string(abi.encodePacked(
                _eyes([514, 567, 489, 349]),
                '<circle class="s0" cx="366" cy="524" r="33.5"/>'
            )),

            // SPIRIT / SOUTH TREE
            string(abi.encodePacked(
                _eyes([320, 496, 583, 364]),
                '<circle class="s0" cx="470" cy="542" r="33.5"/>'
            )),

            // SPIRIT / CENTER TREE
            string(abi.encodePacked(
                _eyes([292, 481, 628, 392]),
                '<circle class="s0" cx="471" cy="474" r="33.5"/>'
            )),

            // ALIEN / U-SHAPE
            string(abi.encodePacked(
                _eyes([507, 456, 454, 456]),
                _path(
                    'M446 540C446 581 521 585 521 538'
                ),
                '<circle class="s0" cx="606" cy="441" r="56.5"/>',
                '<circle class="s0" cx="348" cy="451" r="56.5"/>'
            )),

            // ALIEN / O-SHAPE
            string(abi.encodePacked(
                _eyes([467, 515, 522, 510]),
                '<circle class="s0" cx="503" cy="626" r="33.5"/>',
                '<circle class="s0" cx="343" cy="510" r="56.5"/>',
                '<circle class="s0" cx="625" cy="476" r="56.5"/>'
            )),

            // ALIEN / INVERTED U-SHAPE
            string(abi.encodePacked(
                _eyes([509, 491, 465, 492]),
                _path(
                    'M529 646C529 603 453 610 459 646'
                ),
                '<circle class="s0" cx="353" cy="472" r="56.5"/>',
                '<circle class="s0" cx="620" cy="470" r="56.5"/>'
            )),

            // ALIEN / ROTATED I-SHAPE
            string(abi.encodePacked(
                _eyes([509, 491, 456, 491]),
                _path(
                    'M439 584C450 583 505 582 530 584'
                ),
                '<circle class="s0" cx="344" cy="461" r="56.5"/>',
                '<circle class="s0" cx="623" cy="455" r="56.5"/>'
            )),

            // PRIMORDIAL / ALIGNED
            string(abi.encodePacked(
                _eyes([497, 414, 496, 668]),
                _path(
                    'M451 605C462 624 517 643 542 605'
                ),
                _path(
                    'M425 345C445 373 529 391 559 328'
                ),
                _path(
                    'M397 572C396 448 592 431 593 577'
                )
            )), 

            // PRIMORDIAL / FOUR EYES
            string(abi.encodePacked(
                _eyes([588,496,354,497]),
                _eyes([359,407,591,408]),
                _path(
                    'M662 411.353C646 382 565 353 527 411'
                ),
                _path(
                    'M428 411.797C412 382 331 353 293 411'
                ),
                _path(
                    'M657 499.553C641 470 559 442 522 501'
                ),
                _path(
                    'M423 499.999C407 470 325 442 288 501'
                ),
                _path(
                    'M288 553.666C279 679 650 708 661 562'
                )
            )),

            // PRIMORDIAL / SPIRALING
            string(abi.encodePacked(
                _eyes([357,601,586,356]),
                _path(
                    'M399 620C505 654 684 574 561 391C609 546 469 629 399 620Z'
                ),
                _path(
                    'M398 576C304 505 324 295 550 339C405 344 349 497 398 576Z'
                )
            )),

            // PRIMORDIAL / CYCLOPS
            string(abi.encodePacked(
                '<circle class="s0" cx="474" cy="433" r="49"/>',
                '<circle class="fB i" cx="474" cy="433"/>',
                _path(
                    'M288.098 487.326C281.091 709.646 652.733 747.352 660.929 487.326'
                )
            )),

            // PRIMORDIAL / PRIMAL
            string(abi.encodePacked(
                _eyes([611,489,473,492]),
                '<circle class="fB i" cx="337" cy="489" r="12"/>',
                _path(
                    'M541.847 495.922C542.363 588.19 405.284 600.773 404.68 492.855',
                    ''
                ),
                _path(
                    'M279.036 481.07C279.073 487.698 273.73 493.1 267.103 493.137C260.476 493.174 255.073 487.832 255.036 481.205L279.036 481.07ZM255.036 481.205C254.738 427.86 294.758 396.997 334.783 395.609C354.81 394.914 375.274 401.533 390.803 416.613C406.432 431.79 416.037 454.525 416.203 484.137L392.203 484.271C392.067 459.925 384.311 443.763 374.083 433.831C363.756 423.802 349.87 419.099 335.616 419.594C307.079 420.584 278.818 442.147 279.036 481.07L255.036 481.205Z',
                    'fB nS'
                ),
                _path(
                    'M691.203 491.137C691.24 497.764 685.898 503.167 679.27 503.204C672.643 503.241 667.24 497.899 667.203 491.271L691.203 491.137ZM530.036 488.205C529.738 434.86 569.758 403.997 609.783 402.609C629.81 401.914 650.274 408.533 665.803 423.613C681.432 438.79 691.037 461.525 691.203 491.137L667.203 491.271C667.067 466.925 659.311 450.763 649.083 440.831C638.756 430.802 624.87 426.099 610.616 426.594C582.079 427.584 553.818 449.147 554.036 488.07L530.036 488.205Z',
                    'fB nS'
                )
            ))

        ];

        return
            faces[uint256(keccak256(abi.encodePacked('FACE', tokenId))) % faces.length];
    }


	/** @dev Internal drawing helper function that draws two eye dots.
	  * @param position An array containing the X and Y coordinates for each eye (X1, Y1, X2, Y2)
	  */
    function _eyes(uint16[4] memory position)
        internal
        pure
        returns (string memory)
    {
        return
            string(abi.encodePacked(
                '<circle class="fB i" cx="',
                position[0].uint2str(),
                '" cy="',
                position[1].uint2str(),
                '"/>',
                '<circle class="fB i" cx="',
                position[2].uint2str(),
                '" cy="',
                position[3].uint2str(),
                '"/>'
            ));
    }


	/** @dev Internal drawing helper function that draws a line.
	  * @param position An array containing the X and Y coordinates for each of the line's end points (X1, Y1, X2, Y2).
	  */
    function _line(uint16[4] memory position)
        internal
        pure
        returns (string memory)
    {
        return
            string(abi.encodePacked(
                '<line x1="',
                position[0].uint2str(),
                '" y1="',
                position[1].uint2str(),
                '" x2="',
                position[2].uint2str(),
                '" y2="',
                position[3].uint2str(),
                '"/>'
            ));
    }


	/** @dev Internal drawing helper function that draws a line with the provided class attribute.
	  * @param position An array containing the X and Y coordinates for each of the line's end points (X1, Y1, X2, Y2).
      * @param classNames A string containing the path's `class` attribute
	  */
    function _line(uint16[4] memory position, string memory classNames)
        internal
        pure
        returns (string memory)
    {
        return
            string(abi.encodePacked(
                '<line x1="',
                position[0].uint2str(),
                '" y1="',
                position[1].uint2str(),
                '" x2="',
                position[2].uint2str(),
                '" y2="',
                position[3].uint2str(),
                '" class="',
                classNames,
                '"/>'
            ));
    }


	/** @dev Internal drawing helper function that renders a path element with a default class attribute.
	  * @param d A string containing the path's `d` attribute
	  */
    function _path(string memory d) 
        internal 
        pure 
        returns (string memory) 
    {
        return 
            string(abi.encodePacked(
                '<path class="r" d="', d, '"/>'
            ));
    }


	/** @dev Internal drawing helper function that renders a path element with the provided class attribute.
	  * @param d A string containing the path's `d` attribute.
	  * @param classNames A string containing the path's `class` attribute
	  */
    function _path(string memory d, string memory classNames)
        internal
        pure
        returns (string memory)
    {
        return 
            string(abi.encodePacked(
                '<path class="', classNames, '" d="', d, '"/>'
            ));
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;

library Uint2str {


    function uint2str(uint _i) internal pure returns (string memory _uintAsString) {
        if (_i == 0) {
            return "0";
        }
        uint j = _i;
        uint len;
        while (j != 0) {
            len++;
            j /= 10;
        }
        bytes memory bstr = new bytes(len);
        uint k = len;
        while (_i != 0) {
            k = k-1;
            uint8 temp = (48 + uint8(_i - _i / 10 * 10));
            bytes1 b1 = bytes1(temp);
            bstr[k] = b1;
            _i /= 10;
        }
        return string(bstr);
    }

    
}