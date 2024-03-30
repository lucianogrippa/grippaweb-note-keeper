import { getUUIDFromHeaders } from "@/lib/auth/services/token-check";
import CategoryRepository from "@/lib/services/categoris-repository";
import { NextRequest, NextResponse } from "next/server";

import { CategoriesDto } from "../../dto/categories";
import ResponseDto from "../../dto/ResponseDto";
import { NextApiRequest, NextApiResponse } from "next";
import logger from "@/lib/logger-settings";

export async function GET(_req: NextApiRequest, params? : {params : {
    id: number
}}) {
    const uuid = await getUUIDFromHeaders();

    // ricerca per nome o descrizione
    const id = params?.params.id;

    
    let category: CategoriesDto = null

    try {

        if (!uuid || !id || isNaN(Number(id))) {
            return NextResponse.json({
                error: true,
                message: 'NOT-FOUND'
            }, {
                status: 404,
            })
        }
        
        const categoryRepository = new CategoryRepository(uuid);

        const categoryRersult = await categoryRepository.findById(Number(id));

        if (categoryRersult && categoryRersult.id > 0) {

            const responseData: ResponseDto<CategoriesDto> = {
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

export async function DELETE(_req: NextRequest, params?:{params : {
    id: number
}}) {
    try {
        const uuid = await getUUIDFromHeaders();
    
        const categoryRepository = new CategoryRepository(uuid);
        // ricerca per nome o descrizione
        const id = params?.params.id;
    
        if(!isNaN(id) && Number(id)>0) {
            const deleteObj = await categoryRepository.deleteById(id);
    
            return NextResponse.json({
                error: false,
                message: 'ok',
                data: deleteObj
            }, {
                status: 200,
            });
        }
    } catch (error) {
        logger.error(error);
    }

    return NextResponse.json({
        error: true,
        message: 'ERROR_DELETE'
    }, {
        status: 400,
    });
}