"""
Enterprise-level pagination classes for gym management system.
Optimized for 100k+ users with efficient cursor-based pagination.
"""

from rest_framework.pagination import PageNumberPagination, CursorPagination
from rest_framework.response import Response
from collections import OrderedDict


class StandardResultsSetPagination(PageNumberPagination):
    """
    Standard pagination for most API endpoints.
    Optimized for mobile apps with reasonable page sizes.
    """
    page_size = 50
    page_size_query_param = 'page_size'
    max_page_size = 100
    
    def get_paginated_response(self, data):
        return Response(OrderedDict([
            ('count', self.page.paginator.count),
            ('total_pages', self.page.paginator.num_pages),
            ('current_page', self.page.number),
            ('page_size', self.get_page_size(self.request)),
            ('next', self.get_next_link()),
            ('previous', self.get_previous_link()),
            ('results', data)
        ]))


class SmallResultsSetPagination(PageNumberPagination):
    """
    Small pagination for dashboard widgets and summary views.
    """
    page_size = 20
    page_size_query_param = 'page_size'
    max_page_size = 50


class LargeResultsSetPagination(PageNumberPagination):
    """
    Large pagination for bulk data exports and reports.
    """
    page_size = 200
    page_size_query_param = 'page_size'
    max_page_size = 500


class AttendanceCursorPagination(CursorPagination):
    """
    Cursor-based pagination for attendance records.
    More efficient for large datasets and real-time updates.
    """
    page_size = 50
    ordering = '-check_in_time'
    cursor_query_param = 'cursor'
    page_size_query_param = 'page_size'
    max_page_size = 100
    
    def get_paginated_response(self, data):
        return Response(OrderedDict([
            ('next', self.get_next_link()),
            ('previous', self.get_previous_link()),
            ('count', len(data)),
            ('results', data)
        ]))


class PaymentCursorPagination(CursorPagination):
    """
    Cursor-based pagination for payment records.
    Optimized for financial data with date-based ordering.
    """
    page_size = 25
    ordering = '-payment_date'
    cursor_query_param = 'cursor'
    page_size_query_param = 'page_size'
    max_page_size = 100


class MemberPagination(PageNumberPagination):
    """
    Pagination specifically for member listings.
    Includes member-specific metadata.
    """
    page_size = 30
    page_size_query_param = 'page_size'
    max_page_size = 100
    
    def get_paginated_response(self, data):
        # Calculate additional member statistics
        total_active = sum(1 for member in data if getattr(member, 'is_active', True))
        
        return Response(OrderedDict([
            ('count', self.page.paginator.count),
            ('total_pages', self.page.paginator.num_pages),
            ('current_page', self.page.number),
            ('page_size', self.get_page_size(self.request)),
            ('next', self.get_next_link()),
            ('previous', self.get_previous_link()),
            ('metadata', {
                'total_active_on_page': total_active,
                'total_inactive_on_page': len(data) - total_active,
            }),
            ('results', data)
        ]))