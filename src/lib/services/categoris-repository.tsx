import CategoriesDto from "../models/categories";
import { PagedResults } from "../models/paged-results";

export default class CategoryRepository {
   

    constructor(private uuid: string) { }

    async findById(_id: number): Promise<CategoriesDto> {
      try {
        const category = await prisma.categories.findFirst({
            select: {
                id: true,
                name: true,
                code: true,
                description: true,
                icon: true,
                commons: true
            },
            where: {
                id: _id
            }
        });

        return category;
      } catch (error) {
        console.error(error);
      }

      return null;
    }
    async loadAllCategories(search: string = '', pageIndex: number = 1, maxRowsPerPage: number = 100): Promise<PagedResults<CategoriesDto>> {

        const startIndex = Math.ceil((pageIndex - 1) * maxRowsPerPage);

        const results: PagedResults<CategoriesDto> = {
            items: [],
            maxRowsPerPage,
            totalResults: 0,
            pageIndex
        }

        try {

            let items = [];

            if (!!search) {
                await this.searchCategoriesByText(results, search, startIndex, maxRowsPerPage);
            } else {
                await this.searchAllCategories(results, startIndex, maxRowsPerPage);
            }

        } catch (error) {
            console.error(error);
        }

        return results;
    }

    private async searchAllCategories(results: PagedResults<CategoriesDto>, startIndex: number, maxRowsPerPage: number) {
        results.totalResults = await prisma.categories.count({
            where: {
                OR: [
                    { users_keys: { uuid: this.uuid } },
                    { commons: true }
                ]

            }
        });

        if (results.totalResults > 0) {
            results.items = await prisma.categories.findMany({
                select: {
                    id: true,
                    code: true,
                    description: true,
                    name: true,
                    commons: true,
                    icon: true
                },
                where: {
                    OR: [
                        { users_keys: { uuid: this.uuid } },
                        { commons: true }
                    ]

                },
                skip: startIndex,
                take: maxRowsPerPage,
                orderBy: {
                    name: "asc"
                }
            });
        }
    }

    private async searchCategoriesByText(results: PagedResults<CategoriesDto>, search: string, startIndex: number, maxRowsPerPage: number) {
        results.totalResults = await prisma.categories.count({
            where: {
                AND: [
                    {
                        OR: [
                            { users_keys: { uuid: this.uuid } },
                            { commons: true }
                        ],

                    },
                    {
                        OR: [{
                            code: {
                                contains: search
                            },
                            description: {
                                contains: search
                            },
                            name: {
                                contains: search
                            }
                        }]
                    }
                ]

            },
            orderBy: {
                name: "asc"
            }
        });

        if (results.totalResults > 0) {
            results.items = await prisma.categories.findMany({
                select: {
                    id: true,
                    code: true,
                    description: true,
                    name: true,
                    commons: true,
                    icon: true
                },
                where: {
                    AND: [
                        {
                            OR: [
                                { users_keys: { uuid: this.uuid } },
                                { commons: true }
                            ],

                        },
                        {
                            OR: [{
                                code: {
                                    contains: search
                                },
                                description: {
                                    contains: search
                                },
                                name: {
                                    contains: search
                                }
                            }]
                        }
                    ]

                },
                skip: startIndex,
                take: maxRowsPerPage,
                orderBy: {
                    name: "asc"
                }
            });
        }
    }
}