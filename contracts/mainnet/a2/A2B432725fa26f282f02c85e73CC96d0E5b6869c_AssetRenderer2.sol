// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;

library AssetRenderer2 {

    /**
    * @notice render defs tag
    * @param lgHeadgearAssetId the lgHeadgearAssetId of the gear item
    * @param genderId the gender of the miner (0 == male, 1 == female)
    * @return string of svg
    */
    function renderHairDefs(uint256 lgHeadgearAssetId, uint256 lgHairAssetId, uint256 genderId)
        external
        pure
        returns (string memory)
    {
        return string(abi.encodePacked(
            '%253Cdefs%253E%253Cmask id=\'hm\'%253E%253Cpath d=\'M0,0h57v57h-57z\' fill=\'white\'/%253E',
            (lgHeadgearAssetId < 7 ? '' : '%253Cpath d=\'M0,0h57v22h-57z\' fill=\'black\'/%253E'),
            (lgHairAssetId == 5 ? '%253C/mask%253E%253C/defs%253E%253Cg mask=\'url(%2523hm)\'%253E' : (genderId == 0 ? '%253Cpath d=\'M0,57v-5h1v-1h2v-1h2v-1h4v-1h3v-1h2v-1h2v-1h2v-1h1v-7h-1v-1h-1v-1h-1v-1h-1v-5h28v9h-1v5h-1v3h-1v1h-1v1h2v1h2v1h4v1h2v1h4v1h2v1h1v1h1v2z\' fill=\'black\'/%253E%253C/mask%253E%253C/defs%253E%253Cg mask=\'url(%2523hm)\'%253E' : '%253Cpath d=\'M0,57v-5h1v-1h2v-1h2v-1h4v-1h3v-1h2v-1h3v-1h2v-8h-1v-1h-1v-1h-1v-1h-1v-5h28v9h-1v2h-1v1h-1v2h-1v2h-1v1h-1v2h4v1h2v1h4v1h2v1h4v1h2v1h1v1h1v2z\' fill=\'black\'/%253E%253C/mask%253E%253C/defs%253E%253Cg mask=\'url(%2523hm)\'%253E'))
        ));
    }

    /**
    * @notice render a headgear asset
    * @param lgAssetId the large asset id of the gear item
    * @return string of base64-encoded image
    */
    function renderHeadgear(uint256 lgAssetId, uint256 genderId)
        external
        pure
        returns (string memory)
    {
        string[18] memory HEADGEAR = [
            // START HEADGEAR
            // 0 assassin's mask
            'iVBORw0KGgoAAAANSUhEUgAAADkAAAA5CAYAAACMGIOFAAAAGXRFWHRTb2Z0d2FyZQBBZG9iZSBJbWFnZVJlYWR5ccllPAAAAylJREFUeNrsmsFv0zAUxu2qRw5dDxPHZqtAAs5w4cJf3h64wA0JkEAb3RHtMHZg57LPyxc9PWwnWZzG22wpchunyfv5e355tmv3+7157GVmnkApkAWyQBbIAlkgC+QTh5wP+bG1tvms00PZhrKqToP548Xu3OpzvF/sGQeBjD0Y56uTddO4WCzN4mhprv9cuRrl+Pi5ubz87S7ndbtfZ5ZwuIcP9uCQoQJAgDnAGg5QOFBqOFfevnvvvqNNdIzNwl1DcFo5gvmKbltV68YZ7gS0ZuhMaT6Weo2bHi07wflg6w4brOhsLPf0Ga7dtE1d3I8Ba4iasxRBx6dgV/eMtYe84OBKhgC1gb6A01VNGaUnTwZibnof2DbVs8t4CMW6DaCr4qND0lX7jB2tZAhGdoKItHko2QYcgtLns1FyTLdOGWEfxCxkaACaT6ES658/vjdtofQP53FkBekzllAXu7PoOJadgGtD12er5J3R5x8CzRsmFE6566v/rr1N7zZZj8m2MQUggDlID2CWgadn+N8mumY6d5U56Os3zzbfvn6xfeFjSydZjUkEFwDf3Pz1GszJcl1vdNuQIDQapI6y/AyDubajax/00NdHsjEZMsQ3NrvMULDmQ+WyznhonHzh+zoBHZQyT00OifVShv6YWrGZBjuDsKg/f/ooF7TyTAZ8c0YoyuAT6hTWL16+au4h12kng4Saq8q4eWVobMJ4tgEWELJAOZn2scbYTBF4kqygY3GUoH0V75ruTR54uGonx6dWQLqcTNhrwK3vkOleNtEVwSJmlAw0HVO2bQq70i9/3LoXx1SfVwM3d+SRdXR1QUgo6tsSQAcgsJh6R6s6WXs847TpNN/23uRpnQTl6yPk4r60ri2bOjikXkXnbpbMP+UyRtdkIZv5JABD2Yl8uUsloWwsnePvxCqBnRQSO8Ndp0ESFsZTXamsTO9SAKLYIVGMG6SoObGVLqq3zXXd1jkE5DMm+8+ANsiI/f+2nBPRNTRLYdBK8SpJAqkMseJPDHudk+rxK2chDFgpAZO4a/+sqH29JjQO72urLX/PLpAFskAWyBHKPwEGAAnHFCRzB+E2AAAAAElFTkSuQmCC',
            // 1 misty hood male
            'iVBORw0KGgoAAAANSUhEUgAAADkAAAA5CAYAAACMGIOFAAAAGXRFWHRTb2Z0d2FyZQBBZG9iZSBJbWFnZVJlYWR5ccllPAAAA6BJREFUeNrsmj2O4kAQhW1ETEZIQDITIIHECTg0B+AESCARDAkBIRkZEctD80ZFTfWP222b3XVJIwZj4/761U9Xm/J+vxf/ug2K/8B6yB6yh+whe8geMtGGVU4uy7LWzebzeXDlsd/vo28Su5AZpg44dIPFYnE3jhXX6/Xl2Gg0er6K48/rdrtdmWuyyyrLOvnlrusIByDLAAOw5XJZbLfbl2NyAk6nU+GC5Thix54VEoAaTsPMZrPifD6/qIdj4/H45TwfbGeQAJxOpz/uBzgYBw6bTCY/MARZrVa/ztOghCVoVchhjuxFQKmeNWAASiOgvO5yuRSHw+GpLq/ZbDbvU0IYa1YMctBUke9dgIAjIL3DSmatKKlVjDWtKtUioLSHmxa4B1w2pYxlVVKryEFDOQ7cUpGAcF8JCGWpIl4BGlNrG4PkYEKfaaUkoITDH7IwVETGtiawNXf1AWKgUmG+pzGjakAYYhPuWRewNqSsi3ogHKxUTf7PBBQLqEtM60pWNcBoQBpcFICIP5zDyeCxziBd7qSzpK9GyhiUKx0Y4Kx1b+dK6izJ9zoueYwu+uhCPr87li/AyUSV6rK1IWNmVwPqCQCg0XIB9guQnCThMfcqLdmg6djTsC4XlipKwwRYk/AW7ipd1HeOD4Bqwm0tNbFWb01JrZgLUMaUBHSpSFB8jnOteG5dSWZItFQWnGtREGuyO2l9WQfVOHD2jJZ6uuBbKj56xKNLzVDJasVdtYtKQDkwj5seXaBvkXhkH2i5qAass/tWtV4mKyn7SA6cgOgsQvUz5KY51aytpNyYkq2TtUtABRTgscq92ES3uhiQtYsQLkBD3WNgwyyLmllXPHJPVatHQKsmBmLxGBvTjUMSwpfeY92U0Ba8bweilRLCAVA9vAIaceoCDGXUHD/cGOQAhAtJQK2mmv3Kcca2K3Wh3thuHWHx+p0NPzVgVZUwWVUzazZIK9mEll4pgKk7A7UhpQtZZcJSMSXOrP3aRiGxwctdOqsm+nbYqgI+auYH/1+v197nltmV1Io5ir1eeHexOVjPXfXD1NxGFW+3W7Kr1lq76poYKtapborygdBIddUkSMYj90dp7Ei4ISzjNNVNWR9b7UL4RAmAelZl60XQOm4q911ll5P0fbkep+Mz/ViNGdialNhelbHI3XV8TyeP03nD8vcT0uDPVWLrcMrCvLaSTZvvYSuXdY38+uNvtf4HhD1kD9lDtm5/BBgAJ3vz25dUcNcAAAAASUVORK5CYII=',
            // 2 misty hood female
            'iVBORw0KGgoAAAANSUhEUgAAADkAAAA5CAYAAACMGIOFAAAAGXRFWHRTb2Z0d2FyZQBBZG9iZSBJbWFnZVJlYWR5ccllPAAAA49JREFUeNrsmjGO8jAQhRNETUdJQbUFEkicgENzAE6ABBLF0lBQ0nGB/DzEQ8Ps2I4dJ7D7Z6QVSwhkPr/xzNhJWVVV8ddtUPwH1kP2kD1kD9lD9pCJNow5uSzLRhebz+fBzmO/39e+SN1GZpjqcOgCi8WiMo4V1+v15dhoNLq/iuP37+12uzLXYJcxbZ38cdf3CAcgywADsOVyWWy325djcgBOp1PhgqUfdX3PCglADadhZrNZcT6fX9TDsfF4/HKeD/ZtkACcTqfP8AMcjI7DJpPJE4Ygq9Xqx3kalLAEjYUc5sheBJTqWQ4DUBoB5fcul0txOBzu6vI7m83mc0oI55o1B+k0VeR7FyDgCMjosJJZJ0pqFeuaVpVqEVDaLUwLXAMhm1LGsiqpVaTTUI6OWyoSEOErAaEsVcQrQOvU2tYg6UzoM62UBJRw+EMWhorI2NYAdhauPkA4KhXmexozqgaEYW4iPJsCNoaUdVE7QmelavJ/JqC6gLrEdK5krAFGA9IQogDE/MM5HAweexukK5x0lvTVSDkHZacDA5zV975dSZ0l+V7PSx5jiN5WIV+PFcs34GSiSg3ZxpB1RlcD6gEAoLHkAuw3IDlIImKqmCXZoO25p2FdISxVlIYBsAbhI8JVhqjvHB8A1UTYWmqiV+9MSa2YC1DOKQnoUpGg+BznWvO5cyWZIbGksuBcTUFdk6uTzts6qEbHuWa01NMF31LxtkY8utQMlaxOwlWHqASUjnnC9OgC/YjEI9eBVohqwCa7b7H1MllJuY6k4wTEyiJUP0NhmlPNxkrKjSm5dLJ2CaiAAjzGXIuL6E6bAVm7COECNNQ9BjbMsqiZteORe6paPQJaNTEwF49153TrkITwpfe6YUpoC963A9FJCaEDVA+vgMY8dQGGMmqOBzcGOQARQhJQq6lGP3qecdmV2qi3tltHWLw+suGXBoxVCYMVm1mzQVrJJtR6pQCm7gw0hpQhZJUJS8UYQDYd1n5tq5DY4OUunVUTfTtsTRLJer323rfMrqRWzFHsdeOd3Dq+Lbvqm6ltWmqoNoLUNTFUrJuoiN9MDdWkBp3zkfujNDrEDWE5T98VpkmQvKMEQD2q0jGC5gpTucppHdJXhB+fVQqcf1VqqHFLhQOZ8jvZdgYQkuXPO6TBx1Xq1uGUxvy5dEt9MKJt891sZUS18vTHb7X+AcIesofsITu3fwIMAGcE6Bijid9KAAAAAElFTkSuQmCC',
            // 3 none
            '',
            // 4 enchanted crown
            'iVBORw0KGgoAAAANSUhEUgAAADkAAAA5CAYAAACMGIOFAAAAGXRFWHRTb2Z0d2FyZQBBZG9iZSBJbWFnZVJlYWR5ccllPAAAAblJREFUeNrsmDFuwjAUhu0KqUywdWPkGEWtVHWgF+jEBXqEsjU9Qi/QiRMwoA5ROEZGNrZmol3cvFAHK7KTWHET0/xPinDC48Wf//eeQ7gQgv13u2A9MEACsi+QnPPKY/kwFq58vFbyeT4SLnw6g6QtyHTQxGfTYakf+dw9JZU+3tfkcj4uTbeba49rsu4KDxe78+6uTRoC/VamM6WsLpbqc7ZbyGx66b+SJgWk3b/sa8XR1SXFlU2pU8jvzVUOSvuZKc2KzYfGdE21YHWM06QEWktXCaiqSM1H12WLTSkD/fWjsQsbuAhCagarFOgx67bcVGsZKJtoVSz6BQt3iz5wFejwPklBd7mKpm1Dgra5tThN1yNokqlIY5OPbZZ4AxnFX1b+dVS0XZDWGk/ZxOR3ZYDh9vRpu3B/XpM2ChIApWEUH7Q+H2/5svgPKZWTikTxJ2PrUQ7wuk5uLcKFgQ+QJxi9AgpU2Gb28CavJE1PJgWFQnkP9YmIrqnndf+7dqJkClQ5Ux2MLWBnSvbiRRYgAQlIQAISkIAEJCABCUhAAhKQgAQkIAEJSEACEpCABCQgAQlIV/YjwACgM+38l8jvfwAAAABJRU5ErkJggg==',
            // 5 ancient mask
            'iVBORw0KGgoAAAANSUhEUgAAADkAAAA5CAYAAACMGIOFAAAAGXRFWHRTb2Z0d2FyZQBBZG9iZSBJbWFnZVJlYWR5ccllPAAAAhpJREFUeNrsmj1LxEAQhrOiKFEQO9HKQ60ED8RWYu3vtb70h3C2Kmel2ImFQbGImSOj42bzcckku4kzEHKX7C377MzuzryciuPYG7qteP/ABFIgBVIgBVIgBVIgBXIQtsrVkVIq8+z0wGfN/mfzd2UVEo1WNePRpre7s7a4wM4O/Vp9Xk/fvJfXLwlXgRRIgRRIgextMlBkeMbdPES5bfQztKitk5BgkBAUJQMAhe/pZ/zeJBlggUwymzhJ4X6ynMGG63jkZ2Z/No9qhSB4jbZt4kU2yNvHCBLnOC8/hVBddqBNwVrxJILq3qOgRe+ch4TKA0qtFDQgpdbEMBmX2R78ycXJ1h9AvZ2pL5u7a5jeg5L3VfvpzxEClnqrUiHNWXC3VjSblIKjvY3FxbFT9z6t49x0OoPkHrSTkKYjYpBViE1vdhauNr3ZWbiKJ4ndP3/0s2guW5MgHh/vr/dbGcjbYQEOn989fWbKMpiYq/PtxqFudXdFtQDuAEPv+JzjCOo046m73nrjSRNoVzuuSJLcRjeXKtUIl6db96RpoBS2bJ1ynJuK66+gWD9q9WRApQvTLgnnI0Dn3YkcUnusnYTrr16ThdXPR1MkpNqRe2syFbdQpwnKYE0hbRK0nArXHAkk0HScDCyGKQEMdWnFKci6sAiY9BXS3zoNuSysDoi6rnXIOhOSB8vlQauQRbDcgNYhB6UM2LZvAQYAsylEU82de7EAAAAASUVORK5CYII=',
            // 6 charmed headband
            'iVBORw0KGgoAAAANSUhEUgAAADkAAAA5CAYAAACMGIOFAAAAGXRFWHRTb2Z0d2FyZQBBZG9iZSBJbWFnZVJlYWR5ccllPAAAAg9JREFUeNrs2b9Lw0AUB/CLRCgpYoWC4haxk0IL4q6Dk3+Bs39XN8G/wMnB7iK0g4NUzCYKBetgKDjEvNjXvl4usSQpJfX7QK7NJeY+9+5HolYQBGrVY039gwASSCCBBBJIIIEEEkgggUyO6mErsCxrdZEErF9cKuegWSjUWsZL8161Fbvpu6sUATkG12217U3rPb+Xua32MnCu05oc23eOovJKtWPnn9V/0c/+AxV0rVUoUu/tl6+ulTdrhGOUKUZeX1XcRlTKoGs8v5u5c+2khnEv6o2dF8vn19Z31Fb4w7hxVqL4+H6bXrChIqCM11Ff7VYa6nbQzjWCbFPjqGH3nzfRd2ogDx1qINUnQWXW6Hccb55P6iSOwPRd1j+Fw5UzyUFAHgGFZZKBQ9HD/Jl7nW5oWjhMc41hMxkLgztQwimTevB5eSOWSULRShYHRBM/quehTMOoNs60DELJBg41ZNpxOR+TrsuFlDhermm/cp1mwEOW58dMFrQ5pjfO1GmG+5yExR0f9x97p+EO0il8nySQvhfJRYhgBKF5SmVST5tQf+1xY6QeHdnZWffJ1A2WgXJuZcnSXA1JeMIp4mHFngcoh6GOKsO/GVKfeBjI2WPgImCL7KxUJANNC1LpX7Xkfll2YOqr1qoAl/aqhT9/AAkkkEACCSSQQAIJJJBAAgkkkEACCSSQQJY7fgQYADSdKGHvFBOyAAAAAElFTkSuQmCC',
            // 7 bandana
            'iVBORw0KGgoAAAANSUhEUgAAADkAAAA5CAYAAACMGIOFAAAAGXRFWHRTb2Z0d2FyZQBBZG9iZSBJbWFnZVJlYWR5ccllPAAAAf1JREFUeNrsmU1OwzAQhW0aVbSUFQvELVj1FrDhAtyFO7DmAmzoLbgIQqISqD+RkKqQkZho6o6bEDvglDerKj+OP7+ZzHNqi6Iwhx5H5h8EIAEJSEACEpAtI/utB12PJ7WuY5avbBfmxHbleFyo6XBkzgcDczM+3bn2cb0wr5uNef7Mq2NP66VNFpLhCIrDB+cLgp7ly2igUSEJMBSOglSlIGVjgEaDlIAER/ETQC19GTS0VrPUAOW9BPs9bmHLaAsatYXEAHRTN4kW4tZhDEA5zv3ivVKTyutP+ySryCqEwEoVaVyuz2TMQF2auee1xXCPhaZu1rSZN3mV0+S0CVHKhdQr3UN9MyokAT6cXajQElbWI6UUA8p6cvulXARfGvKCXA6Pzd3HW3wzoDV0qRI7Ec3ZsC2jY/RbLpSE47GaqhrqgLYgGVB6SOk9GdqXOlejiZq6dYrVKRvqfjJtMHIYyrXVarBCt/OXLSXlZDlVpcJJbLUkHCtcGo1SoZOC4QjM98aTVsw37s7KiUyiZ3UR1n2IVqOsHHtK7l0+hTSoUI+szS2KQWdAWVttVUryy4AEdHcEKYK0djzujp0B+/b/yV5IBtReSL3/Wif7Zd8B9+4nDwWw0691vVASkIAEJCABCUhAAhKQgAQkIAEJSEACEpCABCQgAdkqvgQYAOQdZ2oZpwBLAAAAAElFTkSuQmCC',
            // 8 feathered cap
            'iVBORw0KGgoAAAANSUhEUgAAADkAAAA5CAYAAACMGIOFAAAAGXRFWHRTb2Z0d2FyZQBBZG9iZSBJbWFnZVJlYWR5ccllPAAAAc5JREFUeNrs2LFOwzAQBmC76pIFJBgJY9jISFbEIzCSiDfgFRh4Bd4AKYyMGRGsHcNGRsIIEizdMDkLFzdNWmonboH/pKpulTr6HPvuVC6EYH89BuwfBJBAAgmk8xja/DhJkpn6k6Yp90+CpetSeV3wvsrZ0AYYRRELgkB+LopCju/FSGyGWzPXb+xvN87z/vDyNQrEbrzHntJH3jXSaPUIWL2mcPo4z3N2JW7m4tqwb/mrfO8Sa4wMw/B7q5XlZExIhb74uFx67j6wRkjOOYvjWEIV0Pf9KbTC2kAV1hZqjKQgaHUGJ9+rs3jKj9cKapXRCEuZtCnREJTC8zxjaH37mkKt6uS8BaLEQ09zPB7LhHQ+ODO6h0pctJBV9hXOkXTTtnJBr9udkcQSksIU2nRUVtrx6CVDjQmbZZn1nLSgJo1G722d/lQJ2sXTdJp46meEVpoSRH0LE1IlkKPnAwluaxToOv16NZ+qm3r8NBFZI5tAfUe9YVjU9w7ZLwy1kNqCkpA7Q+pFfF2i0zO5qli0XW07nkOHljuTpqSTtq4Kp1CjXht/LgMJJJBAAgkkkEACCSSQQAIJJJBAAgkkkEACCSSQQAIJJJCO4lOAAQCEf/kz0iBcCgAAAABJRU5ErkJggg==',
            // 9 ranger cap
            'iVBORw0KGgoAAAANSUhEUgAAADkAAAA5CAYAAACMGIOFAAAAGXRFWHRTb2Z0d2FyZQBBZG9iZSBJbWFnZVJlYWR5ccllPAAAAXxJREFUeNrs2LFOAjEcx/HWNDHRCWMc1IHECRJG9RF8BJ+VR1B3nEwYlMGYMGHidFLkL1y56921BQG//+XgUsp9+Pd6v6CzLFP7XgfqHxRIkCBBbrzMOifXNxfxz6enkY59zJm1ou6u8gO6p/UnG3zIKzunjrquVGFgBnRRoUAX2n9R2eOb/tNOeoEhODaefUMmWgW70cnprRCzUyfZeLpnR7+T3F4eq4fXyexoq906VMPxV+61Pbol52WsW3bOwftn0OZjUgAFJHXfO1kZtwwsgsp7d9xWLlf34t0LLutk2Q+SW3Y67CliUnaxCrh8vmi873Pz7wkKBkH3pGwCneE4d969H2NL5rJHqed26ycGNQgHjZG1ko1NKilDwCLiLWqagupiK5GVedQHTI0tws+xviDvRa50bQsimg9b1lUTvWxSpxfpfsx3Neqk3bKvz3fjP8vQ5UpABwkSJEiQIEGCBAkSJEiQIEGCBAkSJEiQIEGCBAkSJMhm9S3AAKKYsH+jEASqAAAAAElFTkSuQmCC',
            // 10 leather hat
            'iVBORw0KGgoAAAANSUhEUgAAADkAAAA5CAYAAACMGIOFAAAAGXRFWHRTb2Z0d2FyZQBBZG9iZSBJbWFnZVJlYWR5ccllPAAAAfZJREFUeNrsmsFKw0AQhneliATai4J6rBcv4jPUB9CX3Qewz6BevNhjLbSXFqKIEDPBaYeFbNLd2WaNM1DSkKbZr/+fnT9JdVEUqu91pP5BCaRACqRACqRAetbgUAe6uxo1po7pbKNjhBMdK/HYUJfD42o533ypyXikXpef223XZyfVOmzDenxb62QhEQ6gXha5ujnPttsQsK4oOHyWC5QVEgBRMRsQ1GpTMUDZIF2ATQq6gDlAWSA5FIwJGrWFwOCo/Xwq9EdigaQqxhokfH+bFnQQJW2rclXoDxUEeXuRFS5gl8L71ir/VlrrbpWsUzH0nOy0T7pUpHWaDYIVpPX0nu8tZ9AIAMC2JMdEQ11AIyC4JYkWggOybdpkW7ofvuz9fF0R5SoEBoahG/slXdbZEpQCEHhPgWzLJnVO4kDLS6gHj0OY3+U9XfcZr7eSz4sPPRkPnUEAlPMErOBKIOPbNtjPSbAmTjicE08JiCpWCvq6zltJOGAZtdrOrEbu8fTlHk+XD5bYlZzO1rZtTddKskOG9rQ/YVc7laTw/JNFSRq9MGtij+Toc51Cwn0XO6qlcGnFFutIw1Z28iFJx6Rg2eBzEgBK0Cri7WbYHWAvlKyJYialiUfLvz8EUiAFUiAFUiAFUiAFUiAFUiAFUiAFst/1I8AAx7MirNZCeJoAAAAASUVORK5CYII=',
            // 11 rusty helm
            'iVBORw0KGgoAAAANSUhEUgAAADkAAAA5CAYAAACMGIOFAAAAGXRFWHRTb2Z0d2FyZQBBZG9iZSBJbWFnZVJlYWR5ccllPAAAAn9JREFUeNrsms9Kw0AQxndjW5QqFdFLQTyJF28K0kdQ0Ie1oI/Qi968iCcRerGIIqLUP7Ff5IvTmLTBbJutzkDYZrub7i/f7OzsUhuGofnrFph/YAqpkAqpkAqpkL+0yrR+6GB3eWzWcXr+YCeRnNhJZTxJqL3GYlRe9l7MffXNLL9+vd+lZmBubvvRPeppJ2f31ltIwhFia3U+Klc25+I2nc5TDNpq1b9UPHsw62u16PNj9yP63hVo4BoQA5eAgCPg3dV7VAKMyrFuf7cRKUp18X0eF58qJAEJR4VoF9fPQ7AAofvSCLq9sRC/CBegwSQAAQMQljAMnIb6Zr/2Q02CwnWl4ni+tdYPd00DlHNRGuo5X6WaEljO6VKVpIp0PxlksgClJdVEH6km7tFmf6cRlqokAOF+eQ3zM+9LcKGmE0iE/DSjOoSiYX6yLo/LerWEJJXhvQw6hJageZ9TCqSMqlSAV5qCSSVRSgWz3Nrr3DVNwTSXHQdX1H0rLl01bTCy7rH3PXc73adMQLwAJAWY63G7qgeQck0kGHJUWJx4V8dHXQBG/apmKGH30l0xYA5ysIU6Gtd+sA4eL5la3C+lT9uL6CoXdLFHPMrTF+3gorjy9pmqknKta23Wfx0VR8EV2RI6ddcRmUnblGjOz3hcZyveQObJSOBuRa7SIZPqJZL19swrKbdYDD5QNitpn0lIwtBlEXyksi7czQslu7X+UMbDY0csCUWOLbyAxGEwT9iYu47aVZRlhc5dqRKOJuSWS6Rl7aILeekZDwc/gLXyDEYCzrySGeoeSkAf/nhh9d8fCqmQCqmQCqmQCqmQCqmQCqmQCqmQCvm37VOAAQBcRKGlaSUs1AAAAABJRU5ErkJggg==',
            // 12 bronze helm
            'iVBORw0KGgoAAAANSUhEUgAAADkAAAA5CAYAAACMGIOFAAAAGXRFWHRTb2Z0d2FyZQBBZG9iZSBJbWFnZVJlYWR5ccllPAAAAcRJREFUeNrsmrFOwzAQhu1SBHTp2hdAwFYkZlR2Blh4HAZegndgoQMPUHYk2BreoGuFVJAQCj2EI+M6IfgusYH/pChDYzuf73z3243O81z9deuof2CABCQgAQlIQAZal9NYa1372ZPh1reqY/zwXNlhqHDpcmepbODT/d6XH/YG62p3eZ0d9FaevbpbqGz2qtRQFW2u7xc6dEJXnMGRdTSw297AEZSxMrgyu7iZq+kS2gb1jRUFkgBtuBDAMlAOpFjicQFHO5sFIIXjT+38uP8RDdQvJ1TFIH2As/lbARjiSRu0TtJqtYRIAdrhHrWE+LwoCUhGfViZVyfhSRswZC024c2OdKjagBKeTE7WTR5f1KC/Jg7I7YtVJ11V07S5Kqi1xOMWfwpZ8ijdyQ63N9hwRhhEy66+kPXdQ5JHxgAThaw7w1OhF44ariY8bbu8fTJbqCOJIImeXSksSQjQRevQrEUhwLiebNoLOP5IzJOK+58LZ7uF07pQkxLmSUNK7kDgyRiQWURV02p2TRGUfSRZdcj0qXYmUiUkyrmrU79GVUon5rcJGh9GABKQgAQkIAEJSEACEpCABCQgAQlIQP56exdgAFsb1LS8gb46AAAAAElFTkSuQmCC',
            // 13 iron helm
            'iVBORw0KGgoAAAANSUhEUgAAADkAAAA5CAYAAACMGIOFAAAAGXRFWHRTb2Z0d2FyZQBBZG9iZSBJbWFnZVJlYWR5ccllPAAAAf5JREFUeNrsmsGNgzAQRTFKBRRACRF3OLCNUAnV0Eg4wD2ihBSQFlg+wshiYSGecUx2ZySHS+zkecYz3zaq7/vgr1sY/AMTSIEUSIEUSIG0tMu7fijLsl3V0batciFOlCvFs4SK43hseZ7/+G5d18Hj8RibtqZp1GkhNRyATMA1uC2rqmoE5gJlhQSgCWcD6AI0dAWYJMkMiHB81YqiGPtjXKWUf8g1wOfzOQPaeNIETdOUBMpeQrgAzXD3XkKWXuQEhGGMKevCm1Y5hN2TJqDNWnThzZA7VE1ADk/CzPrpHfJ+vwdRFJEBu66bn2iYPG918ohU4zRb2XfhXi+YdXhUz/71eiWND09iPErIsgt0/CGAI8tqXeprLTqBNBUOnlqaHe2L4q8nZpBz59tqITx1aOqkowGHtfT1W99B0dzWvL7oV3uHRJjqEDUz6x7g0TBFwrGVdu/YNNcEuHoJeuqTgZ3SAG/fPvb448jsIwy3wppjv3sKT1KSiheBTq2NHxOur+5AXF8fOvfkdHyRU48wKDqZFXJZAsqyHJsu9hTAoVmDsntSg+LJuTYpWzcn4WqCcq07yoQ5vwuBSPdtJEgc/HJth05bQqaMiQ/nJwSUrRf7XQjKxday8vU6zbvuJ71KICUvKwmkQAqkQAqkQAqkQAqkQAqkQAqkhX0LMACoRR6lieJO6AAAAABJRU5ErkJggg==',
            // 14 soul shroud
            'iVBORw0KGgoAAAANSUhEUgAAADkAAAA5CAYAAACMGIOFAAAAGXRFWHRTb2Z0d2FyZQBBZG9iZSBJbWFnZVJlYWR5ccllPAAAA19JREFUeNrsm71u2zAQgMkiQJB36JLBWxGgDToEyGBnq7f0HdytS/ocLdBmS96ho7tFGQx0CJwAQTcPWfoORifVZ+vs84WURPJIJq0OEAwblsWP93+SdVmW6l+XF+o/kA6yg+wgO8gOMobsSP7YyfBDY9Itflzq1Ll5RxJqv/dGbb8/NJ1WLs579OHV+ELHgnTaVROUBeSRfOztLV/PZ/Otzx9m0+r1NhqwMyRqi8IhQIggPEAjsBSsNyTIl+FxFPNC4KvxpQisE6TWWg3ejUruezGAuWZDQJ0hQWyg0sBSoM7hnII2RVUJXwU5G0/WwcknBTkXA3ABOOBiFBAWAHBwAJwUoIRleFc8fDdPhiNR7ZlAYUOpBSWveMBvQIs8D5py5bMt62gypz4J0BJw4Jfok0pdpIVEuDpzlQLNpkkaWSkINVsw5bMZBqftignN3GbS8Dv4HWotyc0VggIsBkM9LhorFtS0qc7lnyEUlfcvd5Wa/1IPyw1aBh6dHJLmsbYmXCu97ZQxub/Ja67UhGKlkeODt5X5T/P6ZF2V4xN40KfxvNdgrilqV5dJAMBjoKFBhmvfVXzKOtHoagsoNABVCx24XmdR6RRYSmad8XBA1JgPlK2UxAYhKyRNH1JwdTVzcsgawGuVUbwDjy3oYMBp6z+uXUWywMNnPaa82XbxnwZHyzzYJtWcfv2WLk/CGIKDoqmGNrgUlI4/2o4+RZtmMJuQfNem36TveT2bJPBU4VxDwbzyw9UiztVhUKMcoyULiq4clO84nRT4Lh7Om8x31ffff/IV6Bw0xHe4YPcRAhilGEBN4tQuFPBu75V39yEKaTJbPh1wNdlNe7VJTU+qdjVFQx//xO/B6ORJmKtNmyYfdekvqTZ9qzNRTVagi5p1VPCKyMc/62a4SYqBhkJhsJn3TNcLpkfKnCl+/77q9/rY6DbdYm8CgSj7ufgZ9KxBrKc/rrlGaUDCo41JhubIKJBkt62gXKM2UCmfjJJCyJgCQPurBnpU0JkQaNKlYwlxq2h50gwKsoGFobStMpLSYpTAYwlEKH0yESjozNZ2D8T37nJSSAOoMfry230UMNRckz4CZtKqCZQMw7SET+ocz6AT2DWoafIgAZgNkgH3eY4VL1C6fxN0kM9H/gowAL65SgCwf/y4AAAAAElFTkSuQmCC',
            // 15 genesis helm
            'iVBORw0KGgoAAAANSUhEUgAAADkAAAA5CAYAAACMGIOFAAAAGXRFWHRTb2Z0d2FyZQBBZG9iZSBJbWFnZVJlYWR5ccllPAAAAwtJREFUeNrsms9u00AQxr2Vq6LQSvSWHpB65hRuHMsb8Ki8ATlyoyeuVOLQ3FpBKVQFgr9tvmg8Xa9jrxuvyKxkJY3dnfnNny+TOG65XBb/+9ordmDtBGS5yUWvT57Xavp8cevGKnPnXDGbTmrGP13+cL0hCffu1bE+tayMbR2UgPTn4uqu5mcTbBkDnJ1M/POPX2+Kxfd7/xyvrYxgY7dNSAIC7vzy1r82Pdp/OA73vc8h0GA2CLi4uV/DsURxjpF8//mqtVSGWrRLQOkPYbHgr/apbAJkpLCZvgaZffPyMAtRoX+zYrKG1RkNlisjVWtCkXFECxFFZJtK5CmzqP1Cr2rY1p7kPxAMRqqjkCLEpu/iaNs1sWDB3unxgT/IR58qPx2FCb5r9X3Uk7hQRkn2oAQTxoK9qaEoYtHSE1niftiH/QZxgV3th7YPBskVhaSaoQdZprLJ2ZcwQse0EMAxHZRYtrwdIXhyL+7HYFAc+RpBNeSjcpUlyj6QCivrHvAwwEzr7DHymy59LexKQPwt1VPaAzD1QSeubItsSIQ0LKKpIw5nUhSYFfDr99/iWbnn99N+AMgPCAGx6T27IkI8CMvoyoPZnX/51gtQZrQJMKT6ut02gpRZ1JsRlufXPXhUL9GuKixBmU1tM6TKsoe7QTYA6lFLC0NfsKayxf76baHJ106za59PGnDm4vquuP75xz+evjjoJDyhbG4asJWvrlMmOwOuSgs95Es2ETDbD81QU19eqpdS1hCBSoLkNEIoPYkM2ZtZfv3BWZOgeOTRVXVTK6N8KkgJyLFwPSishgeOZG2L148KGXLWj4OEibyHxc5t9YuspAA8TCtvU/ep1H6eXU/yk8QQgNlkkiUb6bP5WJCDZVICBoQiGRCDd2j4Hi2TqhfnfaeoLN8nY1I/5o2lrdwLGfvOmd3VMshdhwwpq2UyZ0hkSw/YOos5/CYh6UZqNYGc4XE2nXyQ4DkMAENC8ulZaITL5Zclzn7iYpAGaZAGaZAGaZAGaZAGaZAGaZAGucOQ/wQYAFKtQwRx1IOxAAAAAElFTkSuQmCC',
            // 16 skull helm
            'iVBORw0KGgoAAAANSUhEUgAAADkAAAA5CAYAAACMGIOFAAAAGXRFWHRTb2Z0d2FyZQBBZG9iZSBJbWFnZVJlYWR5ccllPAAAAvtJREFUeNrsmt2t4jAQhcMqVVzxnO2AZ65EGaygDgqgDlAoAyk800HyjGgjm4NyomFkm4Dzt3s9koVFEsOXM57MDMzKsoz+d/sV/QALkAEyQAbIABkgA+QPh4yH+qDtdmvNH4/H46zP9DIeCmy1WkWLxeLpeJIknJbVuY/J4XCYdf09eruDAAQYTQIKONN1nasb96WeBFyv162vr5SMiqJ4qAsRKou8YbFAV2Oz2ZRpmjZDWpZlpclM7+d5/hhYr4vvGPflnlK9y+US3W63Zk5bLpePoQ3uDDXr9UrI6aNm3DcgYQB3Op1auy737fl8Hn9PugIMDXCEB6xJPZt1oWanyYANcD6fNwpSVZvVQadR07TmoJCIfC5AGAC1cgQ1wdoeLz570gsS0U+6qjaXa8qgI9WTc+myroxpEHc1qWgDBIQGYTSFXa9X63mTSQbobjYFeRwABKJJQOm2mPtE2bgPFdveDFd6N7kEHQrYYF37kmryWgndlat2AqldTrqaBMQceWkbhbHGfr+fXqnlUpOJd1VZ/LEcThmlCajPrSJ5Ovmi2WU1UIqEAaWW42aMm/FIFVvsp6sYPucMp+SbEZZfWt4J2wLFi+PDKamDj8xqDICFAvzCfmNQwmu9/4pJBh6pqn6g122NvNpvv2uAZQWTEYznYL7b7dgZwP78nlzGI6MsQO/3e5On1srmMuKaejwCFJaN3sjS9aTJbIWyDFD6ucheDz0Ead2nnTzvPYkPfpVXoqbE0KVVm9RuMvWkDRTvccDQ57HBwuCiwk07y2293JWQXEPXfHWQYcaSqyD0VE8SCDcB6slqBa7s03T2DjwAFLBoxSSG59wTMIIPQbViev8icPGGfiyITz9TXv+qRVEfSzjQVWDPFa+2Oc7Tn/Xu6Cytk4o6ejM6EYjEbyBPlYpUelLPSa2k3rPa2HB+9Tp64Hnnep7PfSuDkaNCYYb08Z6cjfG3s1rhts8HL8DRIIe28J+BABkgA2SADJABMkAGyAD5r9hfAQYAS+f6+Tif5loAAAAASUVORK5CYII=',
            // 17 phoenix helm
            'iVBORw0KGgoAAAANSUhEUgAAADkAAAA5CAYAAACMGIOFAAAAGXRFWHRTb2Z0d2FyZQBBZG9iZSBJbWFnZVJlYWR5ccllPAAAAqNJREFUeNrsmr9KA0EQxm8logbE1hcQky6CtZreQhvBR/AlLHwOn8BGC3uDtWA6I76AhU2aqIic+Y6bsBlnL7u3J/njDASjxt353fft7OyiSdM0WfRYSv5BKKRCKuRsRW0akx7v1EuV9Jvuu6H3IbtCrcokpLh+HBg+dnNzOXt/sL366/N7WyviOFcPg4yNjxelJBJBEp3nDzEZKXiCSAxQlNgkQMT9y6c41sluffSQQkGNJLuUDCZFAq4n7QqAXncHXp+lOSkaw+8Jjo8H6/paVvygMSY5aq2lfFJ7clfwpChOL99G7uBKIfHe61fyNHxxYA6a2zYD9VXUCYkAaKj/JTsSEEDP9tcnuuLitp8Bu0Dp976Q4poEOEBhCa5orH2xxosKDOL8cGMMFCqXmatQSUlRX+u67GrbEhA+SXNF6e/woEKUnLh4fa0rqc0Vs9elryoclCp+tF25dXPYMesWJUoqUZEYVe1WPVMyxOpwCl4oNM2CgldJx5PDGt4oSIkSoMu6IesLY0BNPCDaiqCi3f1U3taNBm8lqV1I7CpIgDYobfLkgBDQRkkFvddk0VqVKi91SFKnZP8spFJSweIq+uZe+hSCCTCZvYGHAJKyvpaNUTPqFCJVXF/AECXx+Z71MEPdF33Ugl1tNclSvNHnRScE1F73UztPTirtPEn6Hl+LbNhjD28mDs1UOamq0kZeFE8BIH++T/oA8taOAIYFqh07/nD93039jgfWe+1//+pyqgCclzuejt7WLQok9raYlyo5DUhefBYSkk4gquS8QtptWH432p4FyMr3yar6zZlREhdJUu+ZH2zbVTcCodce0TcD/IbA0cp1yp4BXXOVGcvoP0YopEIqpEIqpEIqpEIqpEIqpEIqpEIqpELOffwIMABPLOUxc/z/CAAAAABJRU5ErkJggg=='
            // END HEADGEAR
        ];
        return string(abi.encodePacked(
            '%253Cimage href=\'data:image/png;base64,',
            HEADGEAR[(lgAssetId == 1 ? (lgAssetId + genderId) : lgAssetId)],
            '\'/%253E'
        ));
    }

    /**
    * @notice renders the ear modifier for the ranger class
    * @param headgearId the id of the headgear item
    * @return string of svg
    */
    function renderEarMod(uint8 headgearId)
        external
        pure
        returns (string memory)
    {
        if(headgearId == 0 || headgearId == 1 || headgearId == 4 || headgearId == 5 || headgearId == 10 || headgearId == 11 || headgearId == 14){
            return '%253Cg%253E%253Cpath d=\'M15,20h1v2h1v1h1v1h1v2h1v3h-1v-1h-1v-1h-1v1h-2z\' fill=\'var(--dms)\'/%253E%253Cpath d=\'M15,20h1v2h1v1h1v1h1v2h1v2h-1v-2h-1v-2h-1v-1h-1v5h-1z\' fill=\'var(--dmb5)\'/%253E%253Cpath d=\'M15,20h1v2h1v1h1v1h1v2h1v3h-1v-1h-1v-1h-1v-1h1v-1h-1v-1h-1v4h-1z\' fill=\'var(--dmb15)\'/%253E%253C/g%253E';
        }
        return '';
    }

    /**
    * @notice return skintone color name
    * @param colorId colorId of skintone
    * @return string of quotation mark-wrapped skintone value
    */
    function skintoneName(uint256 colorId)
        external
        pure
        returns (string memory)
    {
        // Array of potential color values
        string[16] memory SKINTONE_COLORS = [
            '"Porcelain"', // 0
            '"Cream"',     // 1
            '"Sienna"',    // 2
            '"Sand"',      // 3
            '"Beige"',     // 4
            '"Honey"',     // 5
            '"Almond"',    // 6
            '"Bronze"',    // 7
            '"Espresso"',  // 8
            '"Ebony"',     // 9
            '"Demonic"',   // 10
            '"Orc"',       // 11
            '"Djinn"',     // 12
            '"Spectre"',   // 13
            '"Mystic"',    // 14
            '"Golem"'      // 15
        ];
        return SKINTONE_COLORS[colorId];
    }

    /**
    * @notice return hair color name
    * @param colorId colorId of hair color
    * @return string of quotation mark-wrapped hair color value
    */
    function hairColorName(uint256 colorId)
        external
        pure
        returns (string memory)
    {
        // Array of potential color values
        string[8] memory HAIR_COLORS = [
            '"Light Brown"',  // 0
            '"Dark Brown"',   // 1
            '"Dirty Blonde"', // 2
            '"Blonde"',       // 3
            '"Gray"',         // 4
            '"Gray-Brown"',   // 5
            '"Black"',        // 6
            '"Red"'           // 7

        ];
        return HAIR_COLORS[colorId];
    }

    /**
    * @notice return eye color name
    * @param colorId colorId of eyes
    * @return string of quotation mark-wrapped eye color value
    */
    function eyeColorName(uint256 colorId)
        external
        pure
        returns (string memory)
    {
        // Array of potential color values
        string[13] memory EYE_COLORS = [
            '"Black"',       // 0
            '"Gray"',        // 1
            '"Light Green"', // 2
            '"Green"',       // 3
            '"Amber"',       // 4
            '"Light Brown"', // 5
            '"Brown"',       // 6
            '"Light Blue"',  // 7
            '"Blue"',        // 8
            '"Orange"',      // 9
            '"Purple"',      // 10
            '"Red"',         // 11
            '"Transparent"'  // 12
        ];
        return EYE_COLORS[colorId];
    }

    /**
    * @notice return hair type name
    * @param assetId assetId of hair
    * @return string of quotation mark-wrapped hair type value
    */
    function hairTypeName(uint256 assetId)
        external
        pure
        returns (string memory)
    {
        // Array of potential color values
        string[8] memory HAIR_TYPES = [
            '"Bald"',    // 0
            '"Buzzed"',  // 1
            '"Spiked"',  // 2
            '"Mohawk"',  // 3
            '"Short"',   // 4
            '"Braided"', // 5
            '"Long"',    // 6
            '"Ponytail"' // 7
        ];
        return HAIR_TYPES[assetId];
    }

    /**
    * @notice return eye type name
    * @param assetId assetId of eyes
    * @return string of quotation mark-wrapped eye type value
    */
    function eyeTypeName(uint256 assetId)
        external
        pure
        returns (string memory)
    {
        // Array of potential color values
        string[4] memory EYE_TYPES = [
            '"Normal"',   // 0
            '"Angry"',    // 1
            '"Sad"',      // 2
            '"Surprised"' // 3
        ];
        return EYE_TYPES[assetId];
    }

    /**
    * @notice return mouth type name
    * @param assetId assetId of mouth
    * @return string of quotation mark-wrapped mouth type value
    */
    function mouthTypeName(uint256 assetId)
        external
        pure
        returns (string memory)
    {
        // Array of potential color values
        string[8] memory MOUTH_TYPES = [
            '"Toothy Smile"',      // 0
            '"Small Smile"',       // 1
            '"Smile"',             // 2
            '"Frown"',             // 3
            '"Stoic"',             // 4
            '"Sewn"',              // 5
            '"Small Smile Fangs"', // 6
            '"Stoic Fangs"'        // 7
        ];
        return MOUTH_TYPES[assetId];
    }
}