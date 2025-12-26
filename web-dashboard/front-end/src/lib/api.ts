const BASE_URL = 'https://api.mohamed-osama.cloud/api/v1';

export interface User {
  id: number;
  name: string;
  email: string;
  phone?: string | null;
  address?: string | null;
  role: string;
  created_at: string;
}

export interface Brand {
  id: number;
  name: string;
  image: string;
  created_at: string;
}

export interface Product {
  id: number;
  title: string;
  description: string;
  price: string;
  image: string;
  stock: number;
  brand_id?: number | null;
  brand_name?: string | null;
  brand_image?: string | null;
  created_at: string;
}

export interface Rating {
  id: number;
  product_id: number;
  user_id: number;
  user_name?: string;
  user_email?: string;
  rating: number;
  comment?: string;
  created_at: string;
}

export interface ProductRatingsResponse {
  product_id: number;
  average_rating: number;
  total_ratings: number;
  ratings: Rating[];
}

export interface OrderItem {
  id: number;
  order_id: number;
  product_id: number;
  title: string;
  image: string;
  price: string;
  quantity: number;
}

export interface Order {
  id: number;
  user_id: number;
  user_name?: string;
  user_email?: string;
  user_phone?: string | null;
  user_address?: string | null;
  total_price: string;
  status: 'pending' | 'processing' | 'shipped' | 'delivered' | 'cancelled';
  created_at: string;
  items: OrderItem[];
}

export interface ProductsResponse {
  products: Product[];
  pagination: {
    page: number;
    limit: number;
    total: number;
    pages: number;
  };
}

export interface LoginResponse {
  admin_user: User;
  access_token: string;
}

class ApiError extends Error {
  constructor(public status: number, message: string) {
    super(message);
    this.name = 'ApiError';
  }
}

const getToken = (): string | null => {
  return localStorage.getItem('admin_token');
};

const getHeaders = (includeAuth = true): HeadersInit => {
  const headers: HeadersInit = {
    'Content-Type': 'application/json',
  };
  
  if (includeAuth) {
    const token = getToken();
    if (token) {
      headers['Authorization'] = `Bearer ${token}`;
    }
  }
  
  return headers;
};

const handleResponse = async <T>(response: Response): Promise<T> => {
  if (!response.ok) {
    const error = await response.json().catch(() => ({ error: 'Unknown error' }));
    throw new ApiError(response.status, error.error || error.message || 'Request failed');
  }
  return response.json();
};

// Auth
export const adminLogin = async (email: string, password: string): Promise<LoginResponse> => {
  const response = await fetch(`${BASE_URL}/auth/admin/login`, {
    method: 'POST',
    headers: getHeaders(false),
    body: JSON.stringify({ email, password }),
  });
  return handleResponse<LoginResponse>(response);
};

// Users
export const getUsers = async (): Promise<User[]> => {
  const response = await fetch(`${BASE_URL}/users`, {
    headers: getHeaders(),
  });
  return handleResponse<User[]>(response);
};

export const getUser = async (id: number): Promise<User> => {
  const response = await fetch(`${BASE_URL}/users/${id}`, {
    headers: getHeaders(),
  });
  return handleResponse<User>(response);
};

export const updateUser = async (id: number, data: Partial<User & { password?: string }>): Promise<User> => {
  const response = await fetch(`${BASE_URL}/users/${id}`, {
    method: 'PATCH',
    headers: getHeaders(),
    body: JSON.stringify(data),
  });
  return handleResponse<User>(response);
};

export const deleteUser = async (id: number): Promise<{ message: string }> => {
  const response = await fetch(`${BASE_URL}/users/${id}`, {
    method: 'DELETE',
    headers: getHeaders(),
  });
  return handleResponse<{ message: string }>(response);
};

// Brands
export const getBrands = async (): Promise<Brand[]> => {
  const response = await fetch(`${BASE_URL}/brands`, {
    headers: getHeaders(),
  });
  return handleResponse<Brand[]>(response);
};

export const getBrand = async (id: number): Promise<Brand> => {
  const response = await fetch(`${BASE_URL}/brands/${id}`, {
    headers: getHeaders(),
  });
  return handleResponse<Brand>(response);
};

export const createBrand = async (data: {
  name: string;
  image?: File;
}): Promise<Brand> => {
  const formData = new FormData();
  formData.append('name', data.name);
  if (data.image) {
    formData.append('image', data.image);
  }

  const token = getToken();
  const response = await fetch(`${BASE_URL}/brands`, {
    method: 'POST',
    headers: token ? { 'Authorization': `Bearer ${token}` } : {},
    body: formData,
  });
  return handleResponse<Brand>(response);
};

export const updateBrand = async (
  id: number,
  data: {
    name?: string;
    image?: File;
  }
): Promise<Brand> => {
  const formData = new FormData();
  if (data.name !== undefined) formData.append('name', data.name);
  if (data.image) formData.append('image', data.image);

  const token = getToken();
  const response = await fetch(`${BASE_URL}/brands/${id}`, {
    method: 'PATCH',
    headers: token ? { 'Authorization': `Bearer ${token}` } : {},
    body: formData,
  });
  return handleResponse<Brand>(response);
};

export const deleteBrand = async (id: number): Promise<{ message: string }> => {
  const response = await fetch(`${BASE_URL}/brands/${id}`, {
    method: 'DELETE',
    headers: getHeaders(),
  });
  return handleResponse<{ message: string }>(response);
};

// Products
export const getProducts = async (params?: {
  search?: string;
  min_price?: number;
  max_price?: number;
  page?: number;
  limit?: number;
}): Promise<ProductsResponse> => {
  const searchParams = new URLSearchParams();
  if (params?.search) searchParams.append('search', params.search);
  if (params?.min_price) searchParams.append('min_price', params.min_price.toString());
  if (params?.max_price) searchParams.append('max_price', params.max_price.toString());
  if (params?.page) searchParams.append('page', params.page.toString());
  if (params?.limit) searchParams.append('limit', params.limit.toString());
  
  const query = searchParams.toString();
  const response = await fetch(`${BASE_URL}/products${query ? `?${query}` : ''}`, {
    headers: getHeaders(),
  });
  return handleResponse<ProductsResponse>(response);
};

export const createProduct = async (data: {
  title: string;
  description: string;
  price: string | number;
  stock: number;
  brand_id?: number | null;
  image: File;
}): Promise<Product> => {
  const formData = new FormData();
  formData.append('title', data.title);
  formData.append('description', data.description);
  formData.append('price', data.price.toString());
  formData.append('stock', data.stock.toString());
  if (data.brand_id) {
    formData.append('brand_id', data.brand_id.toString());
  }
  formData.append('image', data.image);

  const token = getToken();
  const response = await fetch(`${BASE_URL}/products`, {
    method: 'POST',
    headers: token ? { 'Authorization': `Bearer ${token}` } : {},
    body: formData,
  });
  return handleResponse<Product>(response);
};

export const updateProduct = async (
  id: number,
  data: {
    title?: string;
    description?: string;
    price?: string | number;
    stock?: number;
    brand_id?: number | null;
    image?: File;
  }
): Promise<Product> => {
  const formData = new FormData();
  if (data.title !== undefined) formData.append('title', data.title);
  if (data.description !== undefined) formData.append('description', data.description);
  if (data.price !== undefined) formData.append('price', data.price.toString());
  if (data.stock !== undefined) formData.append('stock', data.stock.toString());
  if (data.brand_id !== undefined) {
    formData.append('brand_id', data.brand_id ? data.brand_id.toString() : '');
  }
  if (data.image) formData.append('image', data.image);

  const token = getToken();
  const response = await fetch(`${BASE_URL}/products/${id}`, {
    method: 'PATCH',
    headers: token ? { 'Authorization': `Bearer ${token}` } : {},
    body: formData,
  });
  return handleResponse<Product>(response);
};

export const deleteProduct = async (id: number): Promise<{ message: string }> => {
  const response = await fetch(`${BASE_URL}/products/${id}`, {
    method: 'DELETE',
    headers: getHeaders(),
  });
  return handleResponse<{ message: string }>(response);
};

// Product Ratings
export const getProductRatings = async (productId: number): Promise<ProductRatingsResponse> => {
  const response = await fetch(`${BASE_URL}/products/${productId}/ratings`, {
    headers: getHeaders(),
  });
  return handleResponse<ProductRatingsResponse>(response);
};

export const deleteRating = async (id: number): Promise<{ message: string }> => {
  const response = await fetch(`${BASE_URL}/ratings/${id}`, {
    method: 'DELETE',
    headers: getHeaders(),
  });
  return handleResponse<{ message: string }>(response);
};

// Orders
export const getOrders = async (): Promise<Order[]> => {
  const response = await fetch(`${BASE_URL}/orders`, {
    headers: getHeaders(),
  });
  return handleResponse<Order[]>(response);
};

export const getOrder = async (id: number): Promise<Order> => {
  const response = await fetch(`${BASE_URL}/orders/${id}`, {
    headers: getHeaders(),
  });
  return handleResponse<Order>(response);
};

export const updateOrderStatus = async (id: number, status: Order['status']): Promise<Order> => {
  const response = await fetch(`${BASE_URL}/orders/${id}`, {
    method: 'PATCH',
    headers: getHeaders(),
    body: JSON.stringify({ status }),
  });
  return handleResponse<Order>(response);
};

export const deleteOrder = async (id: number): Promise<{ message: string }> => {
  const response = await fetch(`${BASE_URL}/orders/${id}`, {
    method: 'DELETE',
    headers: getHeaders(),
  });
  return handleResponse<{ message: string }>(response);
};
