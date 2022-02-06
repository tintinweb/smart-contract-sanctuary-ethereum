// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "base64-sol/base64.sol";

contract BQMetadataHandler is Ownable {
    uint8 numEffect = 4;
    uint8 numBody = 6;
    uint8 numHead = 9;
    uint8 numElbow = 5;
    uint8 numKnee = 5;

    string[] internal effectImages;
    string[] internal bodyImages;
    string[] internal headImages;
    string[] internal elbowImages;
    string[] internal kneeImages;

    string[] public effectNames;
    string[] public bodyNames;
    string[] public headNames;
    string[] public elbowNames;
    string[] public kneeNames;

    constructor() {
        // effectImages = [
        //     "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",
        //     "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",
        //     "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",
        //     "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"
        // ];
        // bodyImages = [
        //     "iVBORw0KGgoAAAANSUhEUgAAAEAAAABABAMAAABYR2ztAAAAJ1BMVEVHcEz/MBD/MBD/MBD/MBD/MBD/MBD/MBD/MBD/MBD/MBD/MBD/MBBRBnTNAAAADHRSTlMA63VdRMj23ho0lrQ4AlLBAAABCElEQVRIx2NgGAWjYBTQHHAuLcIrz1xz5owBPgU+Z86cOYxPQQxQwXF8LjgDAgq4FTCBFQQwMHR6YFdgClZwgmnjmWMpGJItLs6qYPkzR2WAxCF0eQ6ZM8igfAG6gjYk2YNRWMJizpkziWI5YPlTWN3HYtLAwMAGVnAItzchCvAEJTtYwRHcClgh4YBbARdYgQBuBSxgBRvwxFYOgchiAAXnQXzpoYaQArAbHPCmh4M1+BwJDKhjZ84k4FZgA3KCzCG8bow5pHMcn4LTLBN68AQEOKK4QakWR74Cp2iWMyfxRCYordUcwp1ewO7TOYVLAc8ZYbBBAbiDwQB/4bDmCIHSw3DDIC3WAIHDlV6B96l3AAAAAElFTkSuQmCC",
        //     "iVBORw0KGgoAAAANSUhEUgAAAEAAAABACAMAAACdt4HsAAAAXVBMVEVHcExEJs33LxlUJr3/MBATI/87JdcaI/lsJ6UVI/0TI///MBD/MBAoJOwTI/8ZI/n/MBATI/83Jd7NLUP/MBD/MBAqJOj/MBATI/+cKnV1KJz/MBCSKn8AGg1ye+845ETyAAAAHXRSTlMApXSXZQzXVol1spNDPJrCWUQlzb0ZrEca0602lQ36LmEAAADsSURBVFjD7ZbZDoMgEEVVRARxX7tk/v8zK6YtmNhUZp6ach4UH+4BBiREUSAQCAQCv0MMAAk+nsMGI+YBYlxewJsWk+c2DxlGUDkCWL9LOdVrq/OvgEGo0/XgZc4Yy+89HJOcLtwxxZf+1edoXzQnJt4iO3bQjR7NexEeMz/GFaRUwYwRDI5gxAiK/U70R9v8gPsdiTV0BRFVIFD5jlrEqyOQ1I2EGUK6E0jCADLzqLGCar4J5BzsCahQK7mV4LI1F9OcUANo7AmfoQTPdokQyN0/pPzX0ZmAoQbulzens6ZcLPhrBQiKP7qHPQBGzzJo1VaAEAAAAABJRU5ErkJggg==",
        //     "iVBORw0KGgoAAAANSUhEUgAAAEAAAABACAMAAACdt4HsAAAAYFBMVEVHcEwTI/9rJ6f/MBATI/9PJsMeI/X8MBQaI/n/MBD/MBAuJOQTI/9+KJM/JdMTI/8xJOT/MBAqJOfNLUMaI/kTI/9TJ76pK2f/MBD/MBD/MBD/MBCPKoL/ABoAAmLkmTA1PLkxAAAAHnRSTlMADIZbtplEa1ZCk6manNV7HhnTzW0pt8m0xQkI3clMaVMcAAAA7UlEQVRYw+2W2w6DIBBERRHBS9WqvSf7/39ZMW3BRKMMfWnKeREfZmQHWIyiQCAQCAR+h4KIMlwe00TqqSc6YXpJHwSiZ0ZPB8SgtAxofBd9cRxHg3sCGsnfo81EmYjTNK2qjpbJdge3TL7xfb4u7fLktl24WPvwfXd2KlGtfjbSofJlvmqgEIOrZdAiBvl8J7qjjP6CHUfPDG2DyNdAQvrGN8TKMqh9NxIyhWxmUHtMQDcy4qhBqZQEazAdkEMrOUXwMOtZQBNITIc/QAav8QAY9LMzxN3X0SpAXxacmJteoG3MulnPnv8mLPofnmUQM5rTz5iqAAAAAElFTkSuQmCC",
        //     "iVBORw0KGgoAAAANSUhEUgAAAEAAAABACAMAAACdt4HsAAAAV1BMVEVHcEw3Jdt+KJMpJOwTI//7MBX/MBBMJdYVI/1PJsMTI///MBAWI/z/MBATI/9kJ62cKnVFJs3NLUP/MBD/MBA8JdVBJtD/MBATI///MBD/MBAyJd/kMLu84t4RAAAAHHRSTlMA1JYftmhECliZeJOdW0GH063NGXRcTTYvtMWwP+KKUgAAAO1JREFUWMPtlskSgyAQRBURcF+zz/9/Z8QyAau0lOaUCu8iHrphGhiNokAgEAgEfoeOiEZczmgmQ/UNLXSYXtGXGtFLo6cYMSgtA5re67yMp1HinoDmwj+jw0TltcmyjLGethlPB7dNcTA/35f2RSWPC6/3JpansxOVGPQzUQ6Vb2MbpL4GAjF4WgYDYlCsT6I7wugf2HX0zNA2iHwNFKRPPEOUzDLIfQ8SsoR0ZZB7LEA3MuKoQSluCqzBdEAO7eQcQWv28wUtoDIdPoYMlvEdMFCrO8Td99EqQJ9KTtJNX6NtzPqytp7/JjL6H97lEi75xsprvwAAAABJRU5ErkJggg==",
        //     "iVBORw0KGgoAAAANSUhEUgAAAEAAAABACAMAAACdt4HsAAAAZlBMVEVHcEz/MBApJOwyJOD/MBATI/8TI//7MBUeI/UZI/kTI/92KJolJO1XJro/JdP/MBD/MBCDKY//MBATI//NLUMTI/8aI/hdJ7RTJ77/MBBLJsb/MBCpK2f/MBATI/9NJsSPKoJH5DAqV0q8AAAAIXRSTlMAXx/UQAxTbkSxeItil5+VTKEZv82Yooa3tNTFyY4vl91xQiKvAAAA9UlEQVRYw+2WSRKDIBBFUQFxirNmTvr+l4waE6BKS2lWqfA24uJ/e8AGQhwOh8Ph+B0OABDi5QlMZFh9DzNHnJ7DF4HRM6mHAGPQKgYwvIu4C4aVb1rBN2n0WR02Ixd99siSsoFlwt2FW+a28f1oXdrk3o7ExYo631986tFqfPrcIPNlVAPP1qDAGFwUgwpjkOs70Rwq9Sfc72jZBNWA2BqkKL1vW8RSMYhtNxImhFAziC0CGAcZ1FiDtqAcmYOcgNOU4agSPGU/I1QA8xjoMEeDmvh9WJ4N9ak2hyLzPupjiNXAzPTjdKY2F4vhZL1a3k0Y+R9eW743JFa/ZKwAAAAASUVORK5CYII=",
        //     "iVBORw0KGgoAAAANSUhEUgAAAEAAAABACAMAAACdt4HsAAAAWlBMVEVHcEw7JddoJ6kTI/8jJPH/MBATI//7MBQVI/3/MBATI/9UJr0TI///MBAxJOFJJsguJOQZI/kTI///MBCcKnXNLUP/MBD/MBD/MBB1KJx/KZKSKn8AIGYOgIYKBohGAAAAHHRSTlMA14p4IlwMbFpEQZeyk1KmqcKavdPNGQg2rYOVGa795AAAAOtJREFUWMPtltkOgyAURHFDFrXudsn9/99sNU3BRKMMfWnKeVB5mOHeAVHGAoFAIBD4HWoiynH5nRY0qo/pzQXTC/qgED03eooQg9YyoNdYJXXzekrdE5ipitN58CrWWsePgbbJTwe3TXkwf7EvHcpsOm5c7U08nc5OZnKc76lw6HybrxpIxKCzDEbEoFzvRHek0XfY6+iZoW3AfA0EpE99Q7xZBonvRkJKyFcGiUcB0XxpUINWXiuwB3MCFtBKLhH0Zj1rqIDMnPARZGBtKVcDYRWwpJAABWRm2BB30yv0GLO+rL3nvwln/8MTPCkwt+1H3wsAAAAASUVORK5CYII="
        // ];
        // headImages = [
        //     "iVBORw0KGgoAAAANSUhEUgAAAEAAAABABAMAAABYR2ztAAAAHlBMVEVHcEyGPg6GPg6GPg6GPg6GPg6GPg6GPg6GPg6GPg5eFrv7AAAACXRSTlMAuVHtOY7VbyERXDdgAAAAgklEQVRIx2NgGAVDFbQoqeCTZhKeOXPmRAfcCjxngoAATnl2S7CCAJwKGMHy03BbwSQGMsIAnytBJkxXwC3vBLZjIm5HzoQAnEawEVIA8cXMaTit4ACHw0Tc4cDQij8ggaASnwVQV+ANJwZWfDEBAiyWEwkkmHaF0UwzCkbBKKAaAADzljFhv8EXHQAAAABJRU5ErkJggg==",
        //     "iVBORw0KGgoAAAANSUhEUgAAAEAAAABABAMAAABYR2ztAAAAGFBMVEVHcEyGPg6GPg6GPg6GPg6GPg6GPg64Yih0qn0aAAAAB3RSTlMAUb05c5ghVISMwQAAAHhJREFUSMdjYBgFQxUkCwrjk2ZULy8vLzLArcC8HAQUcMqzgOXLHXAqYIIoMMDvhPICfK4EKSgRwC1vCLaiiJAjy3EawU5IAStUAU4r2MDSpQG4HZmKPyCBwB2fBdCwxBtOIGcG4FXAjCeUICBFYDTTjIJRMAqoBgCzbihWhD4oXwAAAABJRU5ErkJggg==",
        //     "iVBORw0KGgoAAAANSUhEUgAAAEAAAABABAMAAABYR2ztAAAAGFBMVEVHcEyGPg6GPg6GPg6GPg6GPg6GPg7hfjzrauEFAAAAB3RSTlMATCrAqohotB7acwAAAH5JREFUSMdjYBgFQxUoCgrhk2YzLy8vLxbArUC9HAQccBsAli8PwKmAGaJAAacCRpATygvwuRKkoAyPIwXBVpTglGeFuKEcpxHshBSwQBXgtIIJ4gTc4cCgAlJggM+b6fgsgIYl3nACeTQArwKm8mICCUZNYDTTjIJRMAqoBgB+UCe9x5oDTAAAAABJRU5ErkJggg==",
        //     "iVBORw0KGgoAAAANSUhEUgAAAEAAAABABAMAAABYR2ztAAAAGFBMVEVHcEyGPg6GPg6GPg6GPg6GPg6GPg7TtJ7FSC37AAAAB3RSTlMAUXs5wKohGLmFggAAAHpJREFUSMdjYBgFQxUkCwrjk2Z0Ly8vLzHArcC8HAQCcMozgeXLFXAqYIEoMMDvhPICfK4EKSgSwC1vCLailJAjy3EawU5IAStUAU4r2CBOwB0ODKkgBQ74vKmOzwJoWOINJ5BHFfAqYC4vIZBgkgRGM80oGAWjgGoAANrvKEbgowHbAAAAAElFTkSuQmCC",
        //     "iVBORw0KGgoAAAANSUhEUgAAAEAAAABABAMAAABYR2ztAAAAGFBMVEVHcEyGPg6GPg6GPg6GPg6GPg6GPg7ZKBeBT1a/AAAAB3RSTlMATCrAiKpoKGUO3QAAAH5JREFUSMdjYBgFQxUoCgrhk2YzLy8vLxbArUC9HAQCcBsAli93wKmAGaJAAacCRpATygvwuRKkoAyPIwXBVpTilGeBuKEcpxHshBSwQhXgtIIJ4gTc4cCgClJggM+b6fgsgIYl3nACedQBrwKm8mICCUZNYDTTjIJRMAqoBgDwoiefdtcLowAAAABJRU5ErkJggg==",
        //     "iVBORw0KGgoAAAANSUhEUgAAAEAAAABABAMAAABYR2ztAAAAGFBMVEVHcEzTbx/Tbx/Tbx/Tbx/Tbx/Tbx/Tbx/ktOEhAAAAB3RSTlMA48clqoRWAGWZiwAAAF1JREFUSMdjYBgFQxYwG+OTVS8ULC8vVMYpz1YOBkV4TAArKMStwJ2QCe6ETFAnzg14FIgTUlBOwA3MEAXlhAIKtwJWQlZAFZTgdoOgkIqLa1jCaJoeBaNgFAwZAACkFiksEidpigAAAABJRU5ErkJggg==",
        //     "iVBORw0KGgoAAAANSUhEUgAAAEAAAABABAMAAABYR2ztAAAAFVBMVEVHcEzTbx/Tbx/Tbx/Tbx/Tbx+MUiQoX/wiAAAABnRSTlMAwqUheEu4oRIsAAAAT0lEQVRIx2NgGAVDFjAb45MVSwMBYZzyLGkQQMgEPArUKFYAsSIRt4I04hSkka+AmZACVkIKCIYkE0Q+CY8bEgWVVFwDRtP0KBgFo2DIAAA33SRwdDXEyQAAAABJRU5ErkJggg==",
        //     "iVBORw0KGgoAAAANSUhEUgAAAEAAAABABAMAAABYR2ztAAAAFVBMVEVHcEzTbx/Tbx/Tbx/Tbx/Tbx/WqIPvlWg4AAAABnRSTlMAv5xoHjnGJ+sHAAAATklEQVRIx2NgGAVDFrC44JMVSwMBUZzyzGkQQMgEPArUKDYBoiARt4I04hSkka+AhZACZooVMEHkk3AqYE1LFBRSMg4YTdOjYBSMgiEDAKuKJE/7XtY7AAAAAElFTkSuQmCC",
        //     "iVBORw0KGgoAAAANSUhEUgAAAEAAAABABAMAAABYR2ztAAAAElBMVEVHcEzTbx/Tbx/Tbx/Tbx/hY0/CYNVKAAAABXRSTlMAvCWMVr53UB4AAABHSURBVEjHY2AYBUMWMCnhkxUNBQEhnPIsoRBAyAQ6KAjErSCUOAWh5CtgIqSAYEAxE6kgGI8bAgUFjU0cRtP0KBgFo2DIAAArGB5QJQQCSQAAAABJRU5ErkJggg=="];
        // elbowImages = [
        //     "iVBORw0KGgoAAAANSUhEUgAAAEAAAABABAMAAABYR2ztAAAAHlBMVEVHcEzsJwfsJwfsJwfsJwfsJwfsJwfsJwfsJwfsJwezmkATAAAACnRSTlMA/uKYIz+5C3FmbNUgwwAAAERJREFUSMdjYBgFo2AUjAIEcDbFJjqtAc5UFHTAlGcXFIazBQUbMBWwCgrB2YlCDvgVFJtgc4OiKgGne47G3igYBfQDAIX6BQego+ywAAAAAElFTkSuQmCC",
        //     "iVBORw0KGgoAAAANSUhEUgAAAEAAAABABAMAAABYR2ztAAAAGFBMVEVHcEzs2gfs2gfs2gfs2gfs2gfs2gfs2gczhDmwAAAAB3RSTlMAyCCpk+NKRXIBAgAAAEFJREFUSMdjYBgFo2AUjAIEYBHBJppsAGe6l2JTIF6MYGJTwFReiFBQiFUBwgRFMWxWmAcRcLpKwmj0jYJRQDcAAGTRBiC5e/s4AAAAAElFTkSuQmCC",
        //     "iVBORw0KGgoAAAANSUhEUgAAAEAAAABABAMAAABYR2ztAAAAGFBMVEVHcEwXojsXojsXojsXojsXojsXojsXojsWZnNEAAAACHRSTlMA/lindC7YFCTJHXIAAABJSURBVEjHY2AYBaNgFIwCBFAzxibKogBnCgo6YFGQKAxjMQkKGmDKA0UDEEwsJrAKCsLtMEzB5gZDMYRirE5ndR+NvlEwCugGAB6EA/StilC2AAAAAElFTkSuQmCC",
        //     "iVBORw0KGgoAAAANSUhEUgAAAEAAAABABAMAAABYR2ztAAAAG1BMVEVHcEyiIheiIheiIheiIheiIheiIheiIheiIhf0qrKrAAAACHRSTlMAyYsXrmLsSCT+I0oAAABGSURBVEjHY2AYBaNgFIwCBGASwSZqFABnerQZYFEg0QpnZnQoYMozdzQi1GJTwN7RAWebCGFzQ0YLAaebFoxG3ygYBXQDAG9/B/52aG1nAAAAAElFTkSuQmCC",
        //     "iVBORw0KGgoAAAANSUhEUgAAAEAAAABABAMAAABYR2ztAAAAGFBMVEVHcEyeF6KeF6KeF6KeF6KeF6KeF6KeF6ItVzGHAAAAB3RSTlMAiOpLsQkp3hrLrQAAAFJJREFUSMdjYBgFo2AUjAIECBQywCJqnABjMauXK2DKM5cXwpiM5eUFmApYysvhbPNyB0wFjOVFCMUq2FymXoLECcCiIFGAgN9YR6N3FIwCqgEAvcwIherUCHgAAAAASUVORK5CYII="
        // ];
        // kneeImages = [
        //     "iVBORw0KGgoAAAANSUhEUgAAAEAAAABABAMAAABYR2ztAAAAFVBMVEVHcEyeF6KeF6KeF6KeF6KeF6KeF6LLaq/KAAAABnRSTlMA2UuHqhlyrzQjAAAAP0lEQVRIx2NgGAWjYBSMglEwCgYGMAkG4FcQliaAU85EAUi4pSXhkmcGSxniNoExLQVEqTLgNwEfMDQYsXEHAGMqBiCd5My+AAAAAElFTkSuQmCC  ",
        //     "iVBORw0KGgoAAAANSUhEUgAAAEAAAABABAMAAABYR2ztAAAAMFBMVEVHcEznGCnSIz2zNFmSRnfnGCnnGCmqOWG5MVN0V5MYiefYIDY7dsfnGCkAAjrnGCnH1ulxAAAADnRSTlMAEfTamm6Ht+9oLcgwXd4u9d0AAABRSURBVEjHY2AYBaNgFIyCUTAKaAMECchz/zfAKZcqACTi///FJc/2XxFI+v//iksB0//vQHLFfwVcCs7//wyi3AVwKVj0/wt+93M2TxixcQsAsN0SDRkvqw0AAAAASUVORK5CYII=",
        //     "iVBORw0KGgoAAAANSUhEUgAAAEAAAABABAMAAABYR2ztAAAAGFBMVEVHcEznrxjnrxjnrxjnrxjnrxjnrxjnrxigGU4MAAAAB3RSTlMAPMiW6WUbU06NzQAAAERJREFUSMdjYBgFo2AUjIJRMAoGBrAqCeCUYwQR4uUOuOSZ3BWAZHh5IS4F5uXFIGXlCvgVMATidEJKuRsBDwSO3LgDANZ7B02gKFm9AAAAAElFTkSuQmCC",
        //     "iVBORw0KGgoAAAANSUhEUgAAAEAAAABABAMAAABYR2ztAAAAGFBMVEVHcEwY5zcY5zcY5zcY5zcY5zcY5zcY5zdF8UhaAAAAB3RSTlMAhsk95mQg7FmVMgAAAEVJREFUSMdjYBgFo2AUjIJRMAoGBjC6K+CUSwAR6eXFOPWWBwBJ8/IyXApYyh3ApAAuBeZgw1kVcTqBqVyBgAdER27cAQBZOgdB/VUQQAAAAABJRU5ErkJggg==",
        //     "iVBORw0KGgoAAAANSUhEUgAAAEAAAABABAMAAABYR2ztAAAAGFBMVEVHcEzFGOfFGOfFGOfFGOfFGOfFGOfFGOeuJpmDAAAACHRSTlMA/pJF3btvIIclVEEAAABNSURBVEjHY2AYBaNgFIyCUTAKaANMA/DLMwkK4JQzAxGKgjhNYBN0YGBgFgSR2AGLoBADA7uLoAIuBYyCokCSPQiP84QIeNDMYMTGLQB/kwPL78/n4QAAAABJRU5ErkJggg=="
        // ];
    }

    function setEffectNames(string[] memory names) public onlyOwner
    {
        require(names.length == numEffect, "names length doesn't match");
        effectNames = names;
    }

    function setEffectImages(string[] memory images) public onlyOwner
    {
        require(images.length == numEffect, "images length doesn't match");
        effectImages = images;
    }

    function setEffectImageById(uint index, string memory image) public onlyOwner
    {
        require(index < numEffect, "index out of bound");
        effectImages[index] = image;
    }

    function setBodyNames(string[] memory names) public onlyOwner
    {
        require(names.length == numBody, "names length doesn't match");
        bodyNames = names;
    }

    function setBodyImages(string[] memory images) public onlyOwner
    {
        require(images.length == numBody, "images length doesn't match");
        bodyImages = images;
    }

    function setBodyImageById(uint index, string memory image) public onlyOwner
    {
        require(index < numBody, "index out of bound");
        bodyImages[index] = image;
    }
    function setHeadNames(string[] memory names) public onlyOwner
    {
        require(names.length == numHead, "names length doesn't match");
        headNames = names;
    }

    function setHeadImages(string[] memory images) public onlyOwner
    {
        require(images.length == numHead, "images length doesn't match");
        headImages = images;
    }

    function setHeadImageById(uint index, string memory image) public onlyOwner
    {
        require(index < numHead, "index out of bound");
        headImages[index] = image;
    }

    function setElbowNames(string[] memory names) public onlyOwner
    {
        require(names.length == numElbow, "names length doesn't match");
        elbowNames = names;
    }

    function setElbowImages(string[] memory images) public onlyOwner
    {
        require(images.length == numElbow, "images length doesn't match");
        elbowImages = images;
    }

    function setElbowImageById(uint index, string memory image) public onlyOwner
    {
        require(index < numElbow, "index out of bound");
        elbowImages[index] = image;
    }

    function setKneeNames(string[] memory names) public onlyOwner
    {
        require(names.length == numKnee, "names length doesn't match");
        kneeNames = names;
    }

    function setKneeImages(string[] memory images) public onlyOwner
    {
        require(images.length == numKnee, "images length doesn't match");
        kneeImages = images;
    }

    function setKneeImageById(uint index, string memory image) public onlyOwner
    {
        require(index < numKnee, "index out of bound");
        kneeImages[index] = image;
    }

    function getTokenURI(uint16 _tokenId, uint8 _effect, uint8 _body, uint8 _head,
                         uint8 _elbow, uint8 _knee, uint16 _power, uint16 _luck,
                         uint16 _win, uint16 _totalBattle)
                         external view returns (string memory)
    {
        string memory svg;

        // using block to avoid max heap error
        {
            string memory header = '<svg id="orc" width="100%" height="100%" version="1.1" viewBox="0 0 60 60" xmlns="http://www.w3.org/2000/svg" xmlns:xlink="http://www.w3.org/1999/xlink">';
            string memory footer = '<style>#orc{shape-rendering: crispedges; image-rendering: -webkit-crisp-edges; image-rendering: -moz-crisp-edges; image-rendering: crisp-edges; image-rendering: pixelated; -ms-interpolation-mode: nearest-neighbor;}</style></svg>';

            string memory svgContent = string(abi.encodePacked(
                '<image x="0" y="0" width="60" height="60" image-rendering="pixelated" preserveAspectRatio="xMidYMid" xlink:href="data:image/png;base64,',
                effectImages[_effect],'"/><image x="0" y="0" width="60" height="60" image-rendering="pixelated" preserveAspectRatio="xMidYMid" xlink:href="data:image/png;base64,',
                bodyImages[_body], '"/><image x="0" y="0" width="60" height="60" image-rendering="pixelated" preserveAspectRatio="xMidYMid" xlink:href="data:image/png;base64,',
                headImages[_head], '"/><image x="0" y="0" width="60" height="60" image-rendering="pixelated" preserveAspectRatio="xMidYMid" xlink:href="data:image/png;base64,',
                elbowImages[_elbow], '"/><image x="0" y="0" width="60" height="60" image-rendering="pixelated" preserveAspectRatio="xMidYMid" xlink:href="data:image/png;base64,',
                kneeImages[_knee], '"/>'
            ));

            svg = Base64.encode(bytes(string(abi.encodePacked(
                header,
                svgContent,
                footer ))));
        }

        string memory attributes = string(abi.encodePacked(
           '"attributes": [',
           '{"trait_type": "Effect", "value": "effect0"},',
           '{"trait_type": "Body", "value": "body0"},',
           '{"trait_type": "Head", "value": "head0"},',
           '{"trait_type": "Elbow", "value": "elbow0"},',
           '{"trait_type": "Knee", "value": "knee0"},',
           '{"display_type": "boost_percentage", "trait_type": "Luck", "value": ', toPercentage(_luck),'},',
           '{"display_type": "number", "trait_type": "Power", "value": ', toString(_power),'},',
           '{"display_type": "number", "trait_type": "Win", "value": ', toString(_win),'},',
           '{"display_type": "number", "trait_type": "Total Battle", "value": ', toString(_totalBattle),'}',
           ']'));

        string memory number = toString(_tokenId);
        
        string memory uri = string(
            abi.encodePacked(
                'data:application/json;base64,',
                Base64.encode(
                    bytes(
                        abi.encodePacked(
                            '{"name":"BQWarrior #', number,'", "description":"BQWarrior is a collection of XXX Warriors ready to pillage the blockchain. With no IPFS or API, these Warriors are the very first role-playing game that takes place 100% on-chain. Spawn new Warriors, battle your Warrior to level up, and pillage different loot pools to get new weapons. This Horde of Warriors will stand the test of time and live on the blockchain for eternity.","image": "',
                            'data:image/svg+xml;base64,',
                            svg,
                            '",',
                            attributes,
                            '}'
                        )
                    )
                )
            )
        );
        return uri;
    }

    function toString(uint256 value) internal pure returns (string memory) {
        // Inspired by OraclizeAPI's implementation - MIT licence
        // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol

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

    function toPercentage(uint256 value) internal pure returns (string memory) {
        bytes memory buffer = new bytes(5);
        uint8 digits = 5;
        for (uint8 i = 0; i < 2; i++) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        digits -= 1;
        buffer[digits] = bytes1(".");
        for (uint8 i = 0; i < 2; i++) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }
}

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

pragma solidity >=0.6.0;

/// @title Base64
/// @author Brecht Devos - <[email protected]>
/// @notice Provides functions for encoding/decoding base64
library Base64 {
    string internal constant TABLE_ENCODE = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/';
    bytes  internal constant TABLE_DECODE = hex"0000000000000000000000000000000000000000000000000000000000000000"
                                            hex"00000000000000000000003e0000003f3435363738393a3b3c3d000000000000"
                                            hex"00000102030405060708090a0b0c0d0e0f101112131415161718190000000000"
                                            hex"001a1b1c1d1e1f202122232425262728292a2b2c2d2e2f303132330000000000";

    function encode(bytes memory data) internal pure returns (string memory) {
        if (data.length == 0) return '';

        // load the table into memory
        string memory table = TABLE_ENCODE;

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
            for {} lt(dataPtr, endPtr) {}
            {
                // read 3 bytes
                dataPtr := add(dataPtr, 3)
                let input := mload(dataPtr)

                // write 4 characters
                mstore8(resultPtr, mload(add(tablePtr, and(shr(18, input), 0x3F))))
                resultPtr := add(resultPtr, 1)
                mstore8(resultPtr, mload(add(tablePtr, and(shr(12, input), 0x3F))))
                resultPtr := add(resultPtr, 1)
                mstore8(resultPtr, mload(add(tablePtr, and(shr( 6, input), 0x3F))))
                resultPtr := add(resultPtr, 1)
                mstore8(resultPtr, mload(add(tablePtr, and(        input,  0x3F))))
                resultPtr := add(resultPtr, 1)
            }

            // padding with '='
            switch mod(mload(data), 3)
            case 1 { mstore(sub(resultPtr, 2), shl(240, 0x3d3d)) }
            case 2 { mstore(sub(resultPtr, 1), shl(248, 0x3d)) }
        }

        return result;
    }

    function decode(string memory _data) internal pure returns (bytes memory) {
        bytes memory data = bytes(_data);

        if (data.length == 0) return new bytes(0);
        require(data.length % 4 == 0, "invalid base64 decoder input");

        // load the table into memory
        bytes memory table = TABLE_DECODE;

        // every 4 characters represent 3 bytes
        uint256 decodedLen = (data.length / 4) * 3;

        // add some extra buffer at the end required for the writing
        bytes memory result = new bytes(decodedLen + 32);

        assembly {
            // padding with '='
            let lastBytes := mload(add(data, mload(data)))
            if eq(and(lastBytes, 0xFF), 0x3d) {
                decodedLen := sub(decodedLen, 1)
                if eq(and(lastBytes, 0xFFFF), 0x3d3d) {
                    decodedLen := sub(decodedLen, 1)
                }
            }

            // set the actual output length
            mstore(result, decodedLen)

            // prepare the lookup table
            let tablePtr := add(table, 1)

            // input ptr
            let dataPtr := data
            let endPtr := add(dataPtr, mload(data))

            // result ptr, jump over length
            let resultPtr := add(result, 32)

            // run over the input, 4 characters at a time
            for {} lt(dataPtr, endPtr) {}
            {
               // read 4 characters
               dataPtr := add(dataPtr, 4)
               let input := mload(dataPtr)

               // write 3 bytes
               let output := add(
                   add(
                       shl(18, and(mload(add(tablePtr, and(shr(24, input), 0xFF))), 0xFF)),
                       shl(12, and(mload(add(tablePtr, and(shr(16, input), 0xFF))), 0xFF))),
                   add(
                       shl( 6, and(mload(add(tablePtr, and(shr( 8, input), 0xFF))), 0xFF)),
                               and(mload(add(tablePtr, and(        input , 0xFF))), 0xFF)
                    )
                )
                mstore(resultPtr, shl(232, output))
                resultPtr := add(resultPtr, 3)
            }
        }

        return result;
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