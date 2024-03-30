import { getUUIDFromHeaders } from "@/lib/auth/services/token-check";
import CategoryRepository from "@/lib/services/categoris-repository";
import { NextRequest, NextResponse } from "next/server";
import ResponseDto from "../dto/ResponseDto";
import logger from "@/lib/logger-settings";
import CategoriesDto from "@/lib/models/categories";

export async function GET(_req: NextRequest) {
    const uuid = await getUUIDFromHeaders();

    // ricerca per nome o descrizione
    const search = _req.nextUrl.searchParams.get("_s") || "";

    const categoryRepository = new CategoryRepository(uuid);
    let categories = []
    // numero massimo di righe per pagina
    const maxRowsPerPage = _req.nextUrl.searchParams.get("_m") || 100;
    // indice della pagina 
    const page = _req.nextUrl.searchParams.get("_p") || "1";

    let totalCategories = 0;

    try {

        const categoryRersult = await categoryRepository.loadAllCategories(search, Number(page), Number(maxRowsPerPage));

        if (categoryRersult && categoryRersult.totalResults > 0) {

            categories = categoryRersult.items;
            totalCategories = categoryRersult.totalResults;

            const responseData: ResponseDto<any> = {
                data: categoryRersult,
                error: false,
                message: 'OK'
            }

            return NextResponse.json(responseData, {
                status: 200,
            })
        }

    } catch (error) {
        console.error(error);
    }

    return NextResponse.json({
        error: true,
        message: 'NOT-FOUND'
    }, {
        status: 404,
    })
}



/**
 * Esegui l'insert di una nuova categoria
 * @param _req 
 */
export async function POST(_req: NextRequest) {
    try {
        const uuid = await getUUIDFromHeaders();

        const categoryRepository = new CategoryRepository(uuid);

        const body = (await _req.json()) as CategoriesDto;

        if (!!body && body.name && body.code && body.description) {

            const saveResult = await categoryRepository.save(body,Number(uuid));

            if(saveResult && saveResult.id>0 ){
                return NextResponse.json({
                    error: false,
                    message: 'ok',
                    data: saveResult
                }, {
                    status: 200,
                })
            }

        } else {
            return NextResponse.json({
                error: true,
                message: 'MISSING-PARAMETER'
            }, {
                status: 400,
            })
        }

    } catch (error) {
        logger.error(error);
    }

    return NextResponse.json({
        error: true,
        message: 'SAVE-ERROR'
    }, {
        status: 400,
    })
}