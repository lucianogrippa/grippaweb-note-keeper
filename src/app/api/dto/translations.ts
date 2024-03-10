export interface TranslationsDTO {
    id: number;
    key: string;
    value: string;
    lang: string;
    ns: number;
    nsCode: string;
}

export interface LangCodesDTO {
    id: number;
    code: string;
    isoCode: string;
}

export interface TranslationsNSDTO {
    id: number;
    code: string;
    descriptions: string;
}